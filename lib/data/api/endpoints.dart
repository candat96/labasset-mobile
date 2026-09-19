/// Mọi path API dùng trong app. `tool/check_openapi.dart` đối chiếu với openapi.json.
class Ep {
  Ep._();

  static const health = '/health';
  static const login = '/v1/auth/login';
  static const refresh = '/v1/auth/refresh';
  static const otpVerify = '/v1/auth/otp/verify';
  static const forgotPassword = '/v1/auth/forgot-password';
  static const me = '/v1/auth/me';
  static const changePassword = '/v1/auth/change-password';
  static const logout = '/v1/auth/logout';
  static const sessions = '/v1/auth/sessions';
  static String session(String id) => '/v1/auth/sessions/$id';

  static const settingsPublic = '/v1/settings/public';

  static const equipmentList = '/v1/equipment';
  static String equipment(String id) => '/v1/equipment/$id';
  static String equipmentByQr(String token) =>
      '/v1/equipment/by-qr/${Uri.encodeComponent(token)}';

  static const supplies = '/v1/supplies';
  static const repairs = '/v1/repairs';
  static const requests = '/v1/requests';

  static const notifications = '/v1/notifications';
  static const notificationsReadAll = '/v1/notifications/read-all';
  static const notificationsPreferences = '/v1/notifications/preferences';
  static String notificationRead(String id) => '/v1/notifications/$id/read';

  static const attachments = '/v1/attachments';
  static String attachment(String id) => '/v1/attachments/$id';

  static const filesPresign = '/v1/files/presign';
  static String fileComplete(String id) => '/v1/files/$id/complete';
  static String fileUrl(String id) => '/v1/files/$id/url';

  static const devices = '/v1/devices';
  static String device(String token) =>
      '/v1/devices/${Uri.encodeComponent(token)}';

  /// Không gắn Authorization, không refresh khi 401.
  static const publicPaths = [
    health,
    login,
    refresh,
    otpVerify,
    forgotPassword,
    '/v1/auth/reset-password',
  ];

  static bool isPublic(String path) =>
      publicPaths.any((p) => path == p || path.startsWith('$p/'));
}
