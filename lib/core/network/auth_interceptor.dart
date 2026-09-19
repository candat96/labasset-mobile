import 'dart:async';

import 'package:dio/dio.dart';

import '../../data/api/endpoints.dart';
import '../storage/session_store.dart';

typedef SessionLost = void Function(String reason);

/// Gắn `Authorization` + `X-Tenant-Id`; 401 → refresh xoay vòng (single-flight) → gửi lại
/// một lần; refresh thất bại hoặc lỗi tenant → xoá phiên và báo `onSessionLost`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.store,
    required Dio refreshDio,
    required Dio retryDio,
    required this.onSessionLost,
  }) : _refreshDio = refreshDio,
       _retryDio = retryDio;

  final SessionStore store;
  final Dio _refreshDio;
  final Dio _retryDio;
  final SessionLost onSessionLost;

  Completer<bool>? _refreshing;

  static const _kRetried = 'auth.retried';

  Map<String, String> authHeaders() {
    final h = <String, String>{};
    final a = store.accessToken;
    final t = store.tenantId;
    if (a != null) h['Authorization'] = 'Bearer $a';
    if (t != null) h['X-Tenant-Id'] = t;
    return h;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!Ep.isPublic(options.path)) options.headers.addAll(authHeaders());
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final res = err.response;
    final opts = err.requestOptions;
    final code = _code(res);
    if (code == 'TENANT_SUSPENDED' || code == 'TENANT_MISMATCH') {
      await _lose('tenant');
      return handler.next(err);
    }
    if (res?.statusCode != 401 ||
        Ep.isPublic(opts.path) ||
        opts.extra[_kRetried] == true) {
      return handler.next(err);
    }
    final ok = await refreshTokens();
    if (!ok) return handler.next(err);
    try {
      final retry = opts.copyWith(extra: {...opts.extra, _kRetried: true});
      retry.headers.addAll(authHeaders());
      final response = await _retryDio.fetch<dynamic>(retry);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Single-flight: các request 401 đồng thời chờ cùng một lần refresh.
  Future<bool> refreshTokens() {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight.future;
    final c = Completer<bool>();
    _refreshing = c;
    _doRefresh().then(c.complete).whenComplete(() => _refreshing = null);
    return c.future;
  }

  Future<bool> _doRefresh() async {
    final rt = store.refreshToken;
    if (rt == null) {
      await _lose('expired');
      return false;
    }
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        Ep.refresh,
        data: {'refreshToken': rt},
      );
      final data = res.data;
      if (res.statusCode != 200 || data == null) {
        await _lose('expired');
        return false;
      }
      await store.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await _lose('expired');
      return false;
    }
  }

  Future<void> _lose(String reason) async {
    if (store.accessToken == null) return;
    await store.clear(reason: reason);
    onSessionLost(reason);
  }

  static String? _code(Response<dynamic>? res) {
    final d = res?.data;
    return d is Map ? d['code'] as String? : null;
  }
}
