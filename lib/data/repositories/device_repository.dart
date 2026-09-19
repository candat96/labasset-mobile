import 'package:dio/dio.dart';

import '../api/endpoints.dart';

class DeviceRepository {
  DeviceRepository(this._dio);
  final Dio _dio;

  Future<void> register(String token, String platform) =>
      _dio.post<void>(Ep.devices, data: {'token': token, 'platform': platform});

  Future<void> unregister(String token) => _dio.delete<void>(Ep.device(token));
}
