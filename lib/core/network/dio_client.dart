import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../storage/session_store.dart';
import 'auth_interceptor.dart';

/// Tạo Dio dùng chung cho toàn app (gắn AuthInterceptor).
Dio createDio({
  required SessionStore store,
  required SessionLost onSessionLost,
}) {
  final options = BaseOptions(
    baseUrl: Env.apiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  );
  final dio = Dio(options);
  final refreshDio = Dio(options);
  dio.interceptors.add(
    AuthInterceptor(
      store: store,
      refreshDio: refreshDio,
      retryDio: dio,
      onSessionLost: onSessionLost,
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: false,
        responseBody: false,
      ),
    );
  }
  return dio;
}
