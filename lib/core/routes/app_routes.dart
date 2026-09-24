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
  static const stock = '/stock';
  static const stockLookup = '/stock/lookup';
  static const supplyDetail = '/supplies/:id';
  static String supply(String id) => '/supplies/$id';
  static const stockReceipts = '/stock/receipts';
  static const stockReceiptNew = '/stock/receipts/new';
  static const stockReceiptDetail = '/stock/receipts/:id';
  static String stockReceipt(String id) => '/stock/receipts/$id';
  static const stockIssues = '/stock/issues';
  static const stockIssueNew = '/stock/issues/new';
  static const stockIssueDetail = '/stock/issues/:id';
  static String stockIssue(String id) => '/stock/issues/$id';
  static const stockTransferNew = '/stock/transfers/new';
  static const stockAlerts = '/stock/alerts';
  static const requests = '/requests';
  static const requestDetail = '/requests/:id';
  static String request(String id) => '/requests/$id';
  static const demand = '/demand';
  static const demandRequestDetail = '/demand/requests/:id';
  static String demandRequest(String id) => '/demand/requests/$id';
  static const demandPeriodDetail = '/demand/periods/:id';
  static String demandPeriod(String id) => '/demand/periods/$id';
  static const stocktakes = '/stocktakes';
  static const stocktakeDetail = '/stocktakes/:id';
  static String stocktake(String id) => '/stocktakes/$id';
  static String stocktakeCount(String id) => '/stocktakes/$id/count';
  static const offlineData = '/offline-data';
  static const reports = '/reports';
  static const ai = '/ai';
  static const aiConversations = '/ai/conversations';
  static const aiChatDetail = '/ai/:id';
  static String aiChat(String id) => '/ai/$id';
  static const repairs = '/repairs';
  static const repairNew = '/repairs/new';
  static const repairDetail = '/repairs/:id';
  static String repair(String id) => '/repairs/$id';
  static const maintenanceTasks = '/maintenance/tasks';
  static const maintenanceTaskDetail = '/maintenance/tasks/:id';
  static String maintenanceTask(String id) => '/maintenance/tasks/$id';
  static const calibrations = '/calibrations';
  static const equipmentList = '/equipment';
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

  /// Vai trò dùng nghiệp vụ kho/VT (thấy tab Kho + thao tác nhập/xuất).
  static const warehouseRoles = ['HOSPITAL_ADMIN', 'EQUIPMENT_STAFF'];

  /// Vai trò khoa (trưởng khoa duyệt/trả lại dự trù, nhân viên khoa xem phiếu).
  static const deptRoles = ['DEPT_HEAD', 'DEPT_USER'];

  /// Vai trò được dùng app: VT/ADM + trưởng khoa/nhân viên khoa.
  /// UI gác theo vai trò, API vẫn là nơi chặn cuối cùng.
  static const allowedRoles = [...warehouseRoles, ...deptRoles];
}
