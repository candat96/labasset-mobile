import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/attachment.dart';

class AttachmentsRepository {
  AttachmentsRepository(this._dio);
  final Dio _dio;

  Future<List<AttachmentView>> list({
    required String entityType,
    required String entityId,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      Ep.attachments,
      queryParameters: {'entityType': entityType, 'entityId': entityId},
    );
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AttachmentView.fromJson)
        .toList();
  }

  Future<AttachmentView> create({
    required String entityType,
    required String entityId,
    required String fileId,
    required String kind,
    String? label,
    int sortOrder = 0,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.attachments,
      data: {
        'entityType': entityType,
        'entityId': entityId,
        'fileId': fileId,
        'kind': kind,
        if (label != null && label.isNotEmpty) 'label': label,
        'sortOrder': sortOrder,
      },
    );
    return AttachmentView.fromJson(res.data!);
  }

  Future<void> delete(String id) => _dio.delete<void>(Ep.attachment(id));
}
