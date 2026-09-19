import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../api/endpoints.dart';
import '../models/attachment.dart';

class FilesRepository {
  FilesRepository(this._dio);
  final Dio _dio;

  /// Dio riêng cho presigned URL / tải tệp (không gắn Bearer).
  static final Dio _plain = Dio();

  Future<PresignResult> presign({
    required String name,
    required String mime,
    required int size,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.filesPresign,
      data: {'name': name, 'mime': mime, 'size': size},
    );
    return PresignResult.fromJson(res.data!);
  }

  Future<void> complete(String fileId) =>
      _dio.post<void>(Ep.fileComplete(fileId));

  Future<FileUrl> url(String fileId) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.fileUrl(fileId));
    return FileUrl.fromJson(res.data!);
  }

  /// Tải tệp về bộ nhớ app (offline) — trả đường dẫn đã lưu.
  Future<String> downloadTo(String url, String name) async {
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/downloads',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    final safe = name.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}-$safe';
    await _plain.download(url, path);
    return path;
  }
}
