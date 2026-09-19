import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/attachment.dart';
import '../../data/repositories/attachments_repository.dart';
import '../../data/repositories/files_repository.dart';
import '../errors/api_error.dart';
import '../sync/outbox_service.dart';

/// Kết quả tải tệp: lên thẳng, xếp hàng offline, hoặc người dùng huỷ chọn.
enum AttachmentUploadStatus { uploaded, queued, cancelled }

class AttachmentUploadResult {
  const AttachmentUploadResult(this.status, [this.attachment]);

  final AttachmentUploadStatus status;
  final AttachmentView? attachment;
}

/// Chọn/nén ảnh → presign → PUT → complete → gắn attachment.
/// Mất mạng: lưu tệp vào bộ nhớ app + đẩy vào outbox.
class AttachmentService {
  AttachmentService({
    required this.attachments,
    required this.files,
    required this.outbox,
    ImagePicker? picker,
    Dio? uploadDio,
    Future<String> Function(Uint8List bytes, String name)? persist,
  }) : _picker = picker ?? ImagePicker(),
       _uploadDio = uploadDio ?? Dio(),
       _persist = persist ?? _persistDefault;

  final AttachmentsRepository attachments;
  final FilesRepository files;
  final OutboxService outbox;
  final ImagePicker _picker;
  final Dio _uploadDio;
  final Future<String> Function(Uint8List bytes, String name) _persist;

  /// Chọn/chụp ảnh rồi tải lên (nén ≤ 1600 px nếu cần).
  Future<AttachmentUploadResult> addImage({
    required String entityType,
    required String entityId,
    required String kind,
    ImageSource source = ImageSource.gallery,
    String? label,
  }) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(source: source);
    } catch (_) {
      return const AttachmentUploadResult(AttachmentUploadStatus.cancelled);
    }
    if (picked == null) {
      return const AttachmentUploadResult(AttachmentUploadStatus.cancelled);
    }
    var bytes = await picked.readAsBytes();
    var name = picked.name;
    var mime = _mimeOf(name);
    if (mime.startsWith('image/')) {
      final compressed = await _compress(picked);
      if (compressed != null) {
        bytes = compressed;
        if (name.toLowerCase().endsWith('.png')) name = '$name.jpg';
        mime = 'image/jpeg';
      }
    }
    return uploadBytes(
      entityType: entityType,
      entityId: entityId,
      kind: kind,
      name: name,
      mime: mime,
      bytes: bytes,
      label: label,
    );
  }

  /// Tải bytes lên (chữ ký PNG, ảnh đã nén…). Offline → outbox.
  Future<AttachmentUploadResult> uploadBytes({
    required String entityType,
    required String entityId,
    required String kind,
    required String name,
    required String mime,
    required Uint8List bytes,
    String? label,
    bool queueOnOffline = true,
  }) async {
    try {
      final presign = await files.presign(
        name: name,
        mime: mime,
        size: bytes.length,
      );
      await _uploadDio.put<void>(
        presign.uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          contentType: mime,
          headers: {
            ...presign.headers.map((k, v) => MapEntry(k, '$v')),
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );
      await files.complete(presign.fileId);
      final view = await attachments.create(
        entityType: entityType,
        entityId: entityId,
        fileId: presign.fileId,
        kind: kind,
        label: label,
      );
      return AttachmentUploadResult(AttachmentUploadStatus.uploaded, view);
    } catch (e) {
      final err = ApiError.from(e);
      final offline = err.code == 'NETWORK_ERROR' || err.status == 0;
      if (!offline || !queueOnOffline) rethrow;
      final path = await _persist(bytes, name);
      await outbox.enqueue('attachment', {
        'entityType': entityType,
        'entityId': entityId,
        'kind': kind,
        'name': name,
        'mime': mime,
        'label': label,
        'path': path,
      });
      return const AttachmentUploadResult(AttachmentUploadStatus.queued);
    }
  }

  Future<Uint8List?> _compress(XFile picked) async {
    if (picked.path.isEmpty) return null;
    try {
      final out = await FlutterImageCompress.compressWithFile(
        picked.path,
        minWidth: 1600,
        minHeight: 1600,
        quality: 80,
      );
      return out;
    } catch (_) {
      return null; // giữ bytes gốc
    }
  }

  static Future<String> _persistDefault(Uint8List bytes, String name) async {
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/outbox',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File(
      '${dir.path}/${DateTime.now().millisecondsSinceEpoch}-$name',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _mimeOf(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }
}

/// Handler outbox cho tệp chờ gửi offline.
class AttachmentOutboxHandler implements OutboxHandler {
  AttachmentOutboxHandler(this.service);
  final AttachmentService service;

  @override
  String get type => 'attachment';

  @override
  Future<void> send(Map<String, dynamic> payload) async {
    final path = payload['path'] as String?;
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) {
      throw ApiError(404, 'ATTACHMENT_FILE_MISSING', 'missing queued file');
    }
    final bytes = await file.readAsBytes();
    final result = await service.uploadBytes(
      entityType: payload['entityType'] as String,
      entityId: payload['entityId'] as String,
      kind: payload['kind'] as String,
      name: payload['name'] as String? ?? 'upload',
      mime: payload['mime'] as String? ?? 'application/octet-stream',
      bytes: bytes,
      label: payload['label'] as String?,
      queueOnOffline: false,
    );
    if (result.status == AttachmentUploadStatus.uploaded) {
      file.delete().ignore(); // dọn tệp tạm, lỗi bỏ qua
    }
  }
}
