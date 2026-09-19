import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/login_result.dart';
import '../models/session_view.dart';
import '../models/user_view.dart';

class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  Future<LoginOutcome> login({
    String? hospitalCode,
    required String username,
    required String password,
    String? deviceInfo,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.login,
      data: {
        if (hospitalCode != null && hospitalCode.isNotEmpty)
          'hospitalCode': hospitalCode,
        'username': username,
        'password': password,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
      },
    );
    return LoginOutcome.fromJson(res.data!);
  }

  Future<LoginResult> verifyOtp(String otpToken, String code) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.otpVerify,
      data: {'otpToken': otpToken, 'code': code},
    );
    return LoginResult.fromJson(res.data!);
  }

  Future<void> forgotPassword({
    String? hospitalCode,
    required String username,
  }) => _dio.post<void>(
    Ep.forgotPassword,
    data: {
      if (hospitalCode != null && hospitalCode.isNotEmpty)
        'hospitalCode': hospitalCode,
      'username': username,
    },
  );

  Future<UserView> me() async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.me);
    return UserView.fromJson(res.data!);
  }

  Future<void> changePassword(String current, String next) => _dio.post<void>(
    Ep.changePassword,
    data: {'current': current, 'next': next},
  );

  Future<List<SessionView>> sessions() async {
    final res = await _dio.get<List<dynamic>>(Ep.sessions);
    return (res.data ?? [])
        .map((e) => SessionView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeSession(String id) => _dio.delete<void>(Ep.session(id));

  /// Thu hồi refresh token hiện tại hoặc mọi phiên (best-effort).
  Future<void> logout({required bool all, String? refreshToken}) =>
      _dio.post<void>(
        Ep.logout,
        queryParameters: {'all': all.toString()},
        data: {if (refreshToken != null) 'refreshToken': refreshToken},
      );
}
