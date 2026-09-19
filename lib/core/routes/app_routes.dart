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
  static const search = '/search';
  static const calendar = '/calendar';
  static const repairs = '/repairs';
  static const repairNew = '/repairs/new';
  static const repairDetail = '/repairs/:id';
  static String repair(String id) => '/repairs/$id';
  static const maintenanceTasks = '/maintenance/tasks';
  static const maintenanceTaskDetail = '/maintenance/tasks/:id';
  static String maintenanceTask(String id) => '/maintenance/tasks/$id';
  static const calibrations = '/calibrations';
  static const equipmentDetail = '/equipment/:id';
  static const equipmentNew = '/equipment/new-quick';
  static String equipment(String id) => '/equipment/$id';
  static const notifications = '/notifications';
  static const notificationsPreferences = '/notifications/preferences';
  static const sync = '/sync';
  static const sessions = '/sessions';
  static const profile = '/profile';
  static const placeholder = '/placeholder/:key';
  static String placeholderFor(String key) => '/placeholder/$key';

  /// Vai trò được dùng app (tinh-nang-mobile.md: VT và ADM).
  static const allowedRoles = ['HOSPITAL_ADMIN', 'EQUIPMENT_STAFF'];
}
