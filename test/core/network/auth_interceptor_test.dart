import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/network/auth_interceptor.dart';
import 'package:labasset_mobile/core/storage/session_store.dart';
import 'package:labasset_mobile/data/models/login_result.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

final _user = {
  'id': 'u',
  'username': 'admin',
  'fullName': 'A',
  'email': null,
  'phone': null,
  'departmentId': null,
  'roles': ['HOSPITAL_ADMIN'],
  'mustChangePassword': false,
  'otpEnabled': false,
};

Map<String, dynamic> _session({String a = 'A1', String r = 'R1'}) => {
  'accessToken': a,
  'refreshToken': r,
  'tenantId': 'T1',
  'user': _user,
};

/// Adapter giả: định tuyến theo path + header để mô phỏng token cũ/mới.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final Future<(int, Object?)> Function(RequestOptions o) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(body ?? {}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late SessionStore store;
  late List<String> logoutReasons;
  late Future<(int, Object?)> Function(RequestOptions o) route;

  Map<String, dynamic> unauthorized() => {
    'code': 'UNAUTHORIZED',
    'message': '',
  };

  setUp(() async {
    final storage = _MockStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    store = SessionStore(storage: storage);
    await store.saveSession(LoginResult.fromJson(_session()));
    logoutReasons = [];
    route = (o) async => (404, {'code': 'NOT_FOUND', 'message': ''});

    final adapter = _FakeAdapter((o) => route(o));
    dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    final refreshDio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        store: store,
        refreshDio: refreshDio,
        retryDio: dio,
        onSessionLost: (reason) => logoutReasons.add(reason),
      ),
    );
  });

  test('attaches bearer + tenant header', () async {
    Map<String, dynamic>? seen;
    route = (o) async {
      seen = o.headers;
      return (200, _user);
    };
    await dio.get<dynamic>('/v1/auth/me');
    expect(seen?['Authorization'], 'Bearer A1');
    expect(seen?['X-Tenant-Id'], 'T1');
  });

  test('does not attach auth on public paths', () async {
    Map<String, dynamic>? seen;
    route = (o) async {
      seen = o.headers;
      return (200, _session());
    };
    await dio.post<dynamic>(
      '/v1/auth/login',
      data: {'username': 'a', 'password': 'b'},
    );
    expect(seen?.containsKey('Authorization'), isFalse);
  });

  test('on 401 refreshes once (rotating) and retries with new token', () async {
    var meCalls = 0;
    var refreshCalls = 0;
    route = (o) async {
      if (o.path == '/v1/auth/refresh') {
        refreshCalls++;
        expect((o.data as Map)['refreshToken'], 'R1');
        return (200, _session(a: 'A2', r: 'R2'));
      }
      if (o.headers['Authorization'] == 'Bearer A2') {
        meCalls++;
        return (200, _user);
      }
      return (401, unauthorized());
    };
    final res = await dio.get<dynamic>('/v1/auth/me');
    expect(res.statusCode, 200);
    expect(refreshCalls, 1);
    expect(store.refreshToken, 'R2');
    expect(store.accessToken, 'A2');
    expect(meCalls, 1);
  });

  test('retries POST with body after refresh', () async {
    Object? received;
    route = (o) async {
      if (o.path == '/v1/auth/refresh') {
        return (200, _session(a: 'A2', r: 'R2'));
      }
      if (o.headers['Authorization'] != 'Bearer A2') {
        return (401, unauthorized());
      }
      received = o.data;
      return (201, {'id': 'd1'});
    };
    await dio.post<dynamic>('/v1/departments', data: {'code': 'XN'});
    expect(received, {'code': 'XN'});
  });

  test('concurrent 401s share one refresh', () async {
    var refreshCalls = 0;
    route = (o) async {
      if (o.path == '/v1/auth/refresh') {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return (200, _session(a: 'A2', r: 'R2'));
      }
      if (o.headers['Authorization'] == 'Bearer A2') return (200, _user);
      return (401, unauthorized());
    };
    await Future.wait([
      dio.get<dynamic>('/v1/auth/me'),
      dio.get<dynamic>('/v1/auth/me'),
      dio.get<dynamic>('/v1/auth/me'),
    ]);
    expect(refreshCalls, 1);
  });

  test('refresh failure clears session with reason expired', () async {
    route = (o) async => (401, unauthorized());
    await expectLater(
      dio.get<dynamic>('/v1/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(store.accessToken, isNull);
    expect(logoutReasons, ['expired']);
  });

  test('does not loop when retry also gets 401', () async {
    var refreshCalls = 0;
    route = (o) async {
      if (o.path == '/v1/auth/refresh') {
        refreshCalls++;
        return (200, _session(a: 'A2', r: 'R2'));
      }
      return (401, unauthorized());
    };
    await expectLater(
      dio.get<dynamic>('/v1/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 1);
  });

  test('TENANT_SUSPENDED clears session with reason tenant', () async {
    route = (o) async => (403, {'code': 'TENANT_SUSPENDED', 'message': ''});
    await expectLater(
      dio.get<dynamic>('/v1/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(logoutReasons, ['tenant']);
    expect(store.accessToken, isNull);
  });

  test('TENANT_NOT_FOUND clears stale session with reason tenant', () async {
    route = (o) async => (404, {'code': 'TENANT_NOT_FOUND', 'message': ''});
    await expectLater(
      dio.get<dynamic>('/v1/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(logoutReasons, ['tenant']);
    expect(store.accessToken, isNull);
    expect(store.tenantId, isNull);
  });

  test('ordinary 404 does not clear session', () async {
    route = (o) async => (404, {'code': 'NOT_FOUND', 'message': ''});
    await expectLater(
      dio.get<dynamic>('/v1/repairs/missing'),
      throwsA(isA<DioException>()),
    );
    expect(logoutReasons, isEmpty);
    expect(store.accessToken, 'A1');
  });

  test('ApiError maps body and network', () {
    final e = ApiError.fromResponse(
      Response(
        requestOptions: RequestOptions(),
        statusCode: 400,
        data: jsonDecode(
          '{"code":"VALIDATION_ERROR","message":"x","details":["code must match","name should not be empty"]}',
        ),
      ),
    );
    expect(e.code, 'VALIDATION_ERROR');
    expect(e.fieldErrors(), {
      'code': 'code must match',
      'name': 'name should not be empty',
    });
    final n = ApiError.from(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    expect(n.code, 'NETWORK_ERROR');
  });
}
