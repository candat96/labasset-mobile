import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/attachment.dart';

class FilesRepository {
  FilesRepository(this._dio);
  final Dio _dio;

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
}
