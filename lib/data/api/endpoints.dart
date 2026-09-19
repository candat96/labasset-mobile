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
  static String equipmentNotes(String id) => '/v1/equipment/$id/notes';
  static String equipmentStatus(String id) => '/v1/equipment/$id/status';
  static String equipmentCounters(String id) => '/v1/equipment/$id/counters';
  static String equipmentNetwork(String id) => '/v1/equipment/$id/network';
  static String equipmentSupplies(String id) => '/v1/equipment/$id/supplies';
  static String equipmentRunway(String id) =>
      '/v1/equipment/$id/supplies/runway';
  static String equipmentEvents(String id) => '/v1/equipment/$id/events';
  static String equipmentTransfers(String id) => '/v1/equipment/$id/transfers';
  static String equipmentTransferApprove(String id, String tid) =>
      '/v1/equipment/$id/transfers/$tid/approve';
  static String equipmentTransferReject(String id, String tid) =>
      '/v1/equipment/$id/transfers/$tid/reject';
  static String equipmentTransferCancel(String id, String tid) =>
      '/v1/equipment/$id/transfers/$tid/cancel';
  static String equipmentAccessories(String id) =>
      '/v1/equipment/$id/accessories';
  static String equipmentAccessory(String id, String aid) =>
      '/v1/equipment/$id/accessories/$aid';
  static String equipmentSoftware(String id) => '/v1/equipment/$id/software';
  static String equipmentSoftwareItem(String id, String sid) =>
      '/v1/equipment/$id/software/$sid';
  static String equipmentSoftwareLicenseKey(String id, String sid) =>
      '/v1/equipment/$id/software/$sid/license-key';
  static String equipmentSoftwareUpgrade(String id, String sid) =>
      '/v1/equipment/$id/software/$sid/upgrade';
  static String equipmentSoftwareHistory(String id, String sid) =>
      '/v1/equipment/$id/software/$sid/history';
  static String equipmentComponents(String id) =>
      '/v1/equipment/$id/components';
  static String equipmentComponentReplace(String id, String cid) =>
      '/v1/equipment/$id/components/$cid/replace';

  static const supplies = '/v1/supplies';
  static String supply(String id) => '/v1/supplies/$id';
  static const repairs = '/v1/repairs';
  static String repair(String id) => '/v1/repairs/$id';
  static String repairAccept(String id) => '/v1/repairs/$id/accept';
  static String repairAssign(String id) => '/v1/repairs/$id/assign';
  static const repairAssignSuggest = '/v1/repairs/assign/suggest';
  static String repairAssignmentsRespond(String id) =>
      '/v1/repairs/$id/assignments/respond';
  static String repairDiagnosis(String id) => '/v1/repairs/$id/diagnosis';
  static String repairStatus(String id) => '/v1/repairs/$id/status';
  static String repairComplete(String id) => '/v1/repairs/$id/complete';
  static String repairAcceptance(String id) => '/v1/repairs/$id/acceptance';
  static String repairClose(String id) => '/v1/repairs/$id/close';
  static String repairCancel(String id) => '/v1/repairs/$id/cancel';
  static String repairLogs(String id) => '/v1/repairs/$id/logs';
  static String repairParts(String id) => '/v1/repairs/$id/parts';
  static String repairCosts(String id) => '/v1/repairs/$id/costs';
  static String repairVendors(String id) => '/v1/repairs/$id/vendors';
  static String repairSignatures(String id) => '/v1/repairs/$id/signatures';
  static String repairReportPdf(String id) => '/v1/repairs/$id/report.pdf';
  static const requests = '/v1/requests';

  static const notifications = '/v1/notifications';
  static const notificationsReadAll = '/v1/notifications/read-all';
  static const notificationsPreferences = '/v1/notifications/preferences';
  static String notificationRead(String id) => '/v1/notifications/$id/read';

  static const maintenanceTasks = '/v1/maintenance/tasks';
  static const departments = '/v1/departments';
  static const faults = '/v1/faults';
  static const faultsSuggest = '/v1/faults/suggest';

  static const stockAlerts = '/v1/stock/alerts';
  static const stockLots = '/v1/stock/lots';
  static String stockLotOpen(String id) => '/v1/stock/lots/$id/open';

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
