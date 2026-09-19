class Routes {
  Routes._();

  static const login = '/login';
  static const otp = '/login/otp';
  static const forgotPassword = '/forgot-password';
  static const changePassword = '/change-password';
  static const noAccess = '/no-access';
  static const lock = '/lock';

  static const shell = '/';
  static const scan = '/scan';
  static const equipmentDetail = '/equipment/:id';
  static String equipment(String id) => '/equipment/$id';
  static const notifications = '/notifications';
  static const sessions = '/sessions';
  static const profile = '/profile';
  static const placeholder = '/placeholder/:key';
  static String placeholderFor(String key) => '/placeholder/$key';

  /// Vai trò được dùng app (tinh-nang-mobile.md: VT và ADM).
  static const allowedRoles = ['HOSPITAL_ADMIN', 'EQUIPMENT_STAFF'];
}
