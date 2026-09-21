import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/login_result.dart';
import '../../data/models/user_view.dart';

/// Phiên đăng nhập: token trong secure storage, user/cờ trong Rx để UI phản ứng.
class SessionStore extends GetxService {
  SessionStore({FlutterSecureStorage? storage, bool checkFreshInstall = true})
    : _storage = storage ?? const FlutterSecureStorage(),
      _checkFreshInstall = checkFreshInstall;

  final FlutterSecureStorage _storage;
  final bool _checkFreshInstall;

  static const _kAccess = 'accessToken';
  static const _kRefresh = 'refreshToken';
  static const _kTenant = 'tenantId';
  static const _kUser = 'user';
  static const _kBiometric = 'biometricEnabled';
  static const _kTheme = 'themeMode';
  static const _kPushToken = 'pushToken';
  static const _kTextScale = 'textScale';

  String? accessToken;
  String? refreshToken;
  String? tenantId;
  String? pushToken;
  final Rxn<UserView> user = Rxn<UserView>();
  final RxBool biometricEnabled = false.obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  /// Cỡ chữ lớn (1.0 = mặc định, 1.15 = lớn).
  final RxDouble textScale = 1.0.obs;

  /// Lý do rời phiên gần nhất (hiển thị ở màn login).
  String? lastLogoutReason;

  bool get isLoggedIn => accessToken != null && user.value != null;

  bool hasRole(List<String> roles) {
    final u = user.value;
    return u != null && roles.any(u.roles.contains);
  }

  Future<SessionStore> load() async {
    if (_checkFreshInstall) await _clearKeychainIfFreshInstall();
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
    textScale.value =
        double.tryParse(await _storage.read(key: _kTextScale) ?? '') ?? 1.0;
    themeMode.value = switch (await _storage.read(key: _kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return this;
  }

  /// iOS giữ Keychain sau khi gỡ app → cài lại vẫn còn phiên cũ. Đánh dấu bằng
  /// file trong sandbox (mất khi gỡ app): không thấy dấu ⇒ cài mới ⇒ xoá sạch.
  Future<void> _clearKeychainIfFreshInstall() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final marker = File('${dir.path}/.installed');
      if (await marker.exists()) return;
      await _storage.deleteAll();
      await marker.create(recursive: true);
    } catch (_) {
      // Không chặn khởi động nếu không truy cập được sandbox.
    }
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

  Future<void> setTextScale(double v) async {
    textScale.value = v;
    await _storage.write(key: _kTextScale, value: '$v');
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
