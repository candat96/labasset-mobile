import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../data/models/login_result.dart';
import '../../data/models/user_view.dart';

/// Phiên đăng nhập: token trong secure storage, user/cờ trong Rx để UI phản ứng.
class SessionStore extends GetxService {
  SessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'accessToken';
  static const _kRefresh = 'refreshToken';
  static const _kTenant = 'tenantId';
  static const _kUser = 'user';
  static const _kBiometric = 'biometricEnabled';
  static const _kTheme = 'themeMode';
  static const _kPushToken = 'pushToken';

  String? accessToken;
  String? refreshToken;
  String? tenantId;
  String? pushToken;
  final Rxn<UserView> user = Rxn<UserView>();
  final RxBool biometricEnabled = false.obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  /// Lý do rời phiên gần nhất (hiển thị ở màn login).
  String? lastLogoutReason;

  bool get isLoggedIn => accessToken != null && user.value != null;

  bool hasRole(List<String> roles) {
    final u = user.value;
    return u != null && roles.any(u.roles.contains);
  }

  Future<SessionStore> load() async {
    accessToken = await _storage.read(key: _kAccess);
    refreshToken = await _storage.read(key: _kRefresh);
    tenantId = await _storage.read(key: _kTenant);
    pushToken = await _storage.read(key: _kPushToken);
    final u = await _storage.read(key: _kUser);
    if (u != null) {
      try {
        user.value = UserView.fromJson(jsonDecode(u) as Map<String, dynamic>);
      } catch (_) {
        user.value = null;
      }
    }
    biometricEnabled.value = (await _storage.read(key: _kBiometric)) == 'true';
    themeMode.value = switch (await _storage.read(key: _kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return this;
  }

  Future<void> saveSession(LoginResult r) async {
    lastLogoutReason = null;
    await saveTokens(r.accessToken, r.refreshToken);
    tenantId = r.tenantId;
    await _storage.write(key: _kTenant, value: r.tenantId);
    await setUser(r.user);
  }

  Future<void> saveTokens(String access, String refresh) async {
    accessToken = access;
    refreshToken = refresh;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> setUser(UserView u) async {
    user.value = u;
    await _storage.write(key: _kUser, value: jsonEncode(u.toJson()));
  }

  Future<void> setBiometric(bool v) async {
    biometricEnabled.value = v;
    await _storage.write(key: _kBiometric, value: v.toString());
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode.value = m;
    await _storage.write(key: _kTheme, value: m.name);
  }

  Future<void> setPushToken(String? t) async {
    pushToken = t;
    if (t == null) {
      await _storage.delete(key: _kPushToken);
    } else {
      await _storage.write(key: _kPushToken, value: t);
    }
  }

  /// Xoá phiên (giữ tuỳ chọn giao diện/sinh trắc).
  Future<void> clear({String? reason}) async {
    lastLogoutReason = reason;
    accessToken = null;
    refreshToken = null;
    tenantId = null;
    user.value = null;
    for (final k in [_kAccess, _kRefresh, _kTenant, _kUser]) {
      await _storage.delete(key: k);
    }
  }
}
