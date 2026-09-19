import 'dart:async';

import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/sync/outbox_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/repair_detail.dart';
import '../../data/repositories/repairs_repository.dart';

/// Handler outbox cho nhật ký sửa chữa (offline, clientId idempotent).
class RepairLogOutboxHandler implements OutboxHandler {
  RepairLogOutboxHandler(this.repairs);

  final RepairsRepository repairs;

  static const typeName = 'repair_log';

  @override
  String get type => typeName;

  @override
  Future<void> send(Map<String, dynamic> payload) async {
    await repairs.addLog(
      payload['ticketId'] as String,
      clientId: payload['clientId'] as String,
      at: payload['at'] as String,
      action: payload['action'] as String,
      note: payload['note'] as String?,
      durationMinutes: payload['durationMinutes'] as num?,
    );
  }
}

/// Chi tiết phiếu sửa chữa: header, ma trận hành động, tổng quan, nhật ký offline.
class RepairDetailController extends GetxController {
  RepairDetailController({
    required this.repairs,
    required this.outbox,
    required this.id,
    this.userId = '',
    this.roles = const [],
  });

  final RepairsRepository repairs;
  final OutboxService outbox;
  final String id;
  final String userId;
  final List<String> roles;

  static const openStatuses = {
    'accepted',
    'in_progress',
    'awaiting_parts',
    'awaiting_vendor',
  };
  static const statusTargets = [
    'in_progress',
    'awaiting_parts',
    'awaiting_vendor',
  ];

  final Rxn<RepairDetail> item = Rxn<RepairDetail>();
  final RxList<RepairLog> serverLogs = <RepairLog>[].obs;
  final RxList<RepairLog> pendingLogs = <RepairLog>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  bool get isAdmin => roles.contains('HOSPITAL_ADMIN');
  bool get isStaff => roles.contains('EQUIPMENT_STAFF') || isAdmin;
  bool get isAssignee {
    final d = item.value;
    if (d == null || userId.isEmpty) return false;
    return d.assigneeId == userId || d.assistantIds.contains(userId);
  }

  /// Nhật ký gộp server + chờ đồng bộ, mới nhất trước.
  List<RepairLog> get mergedLogs {
    final all = [...serverLogs, ...pendingLogs];
    all.sort((a, b) => b.at.compareTo(a.at));
    return all;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final d = await repairs.detail(id);
      item.value = d;
      serverLogs.assignAll(d.logs);
      await loadPendingLogs();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadPendingLogs() async {
    final all = await outbox.items();
    pendingLogs.assignAll(
      all
          .where((i) => i.type == RepairLogOutboxHandler.typeName)
          .where((i) => i.payload['ticketId'] == id)
          .map(
            (i) => RepairLog(
              at: i.payload['at'] as String? ?? i.createdAt.toIso8601String(),
              action: i.payload['action'] as String? ?? '',
              note: i.payload['note'] as String?,
              durationMinutes: i.payload['durationMinutes'] as num?,
              clientId: i.payload['clientId'] as String?,
              pending: true,
            ),
          ),
    );
  }

  // ── Ma trận nút theo trạng thái/role (web 03 B4) ───────────
  bool get canAccept => item.value?.status == 'new' && isStaff;
  bool get canAssign => isAdmin && !_closed;
  bool get canRespond => item.value?.pendingAssignmentFor(userId) != null;
  bool get canDiagnose =>
      (isAssignee || isAdmin) && openStatuses.contains(item.value?.status);
  bool get canChangeStatus => canDiagnose;
  bool get canComplete =>
      isAssignee && openStatuses.contains(item.value?.status);
  bool get canAcceptance =>
      item.value?.status == 'completed' &&
      (isAdmin || roles.contains('DEPT_HEAD') || roles.contains('DEPT_USER'));
  bool get canClose =>
      isAdmin &&
      (item.value?.status == 'acceptance' || item.value?.status == 'completed');
  bool get canCancel => isAdmin && !_closed;
  bool get _closed => const [
    'completed',
    'acceptance',
    'closed',
    'cancelled',
  ].contains(item.value?.status);

  // ── Hành động ──────────────────────────────────────────────
  Future<bool> _run(Future<void> Function() action, String okKey) async {
    try {
      await action();
      AppSnackbar.success(okKey.tr);
      await load();
      return true;
    } catch (e) {
      final code = ApiError.from(e).code;
      if (code == 'REPAIR_INVALID_TRANSITION') {
        AppSnackbar.info('errors.REPAIR_INVALID_TRANSITION'.tr);
      } else {
        AppSnackbar.error(e);
      }
      return false;
    }
  }

  Future<bool> accept() =>
      _run(() => repairs.accept(id), 'repairs.action.accepted');

  Future<bool> respond({required bool accepted, String? note}) => _run(
    () => repairs.respondAssignment(
      id,
      response: accepted ? 'accepted' : 'declined',
      note: note,
    ),
    accepted ? 'repairs.action.respondedYes' : 'repairs.action.respondedNo',
  );

  Future<bool> assign({
    required String primaryUserId,
    List<String> assistantIds = const [],
    String? dueAt,
  }) => _run(
    () => repairs.assign(
      id,
      primaryUserId: primaryUserId,
      assistantIds: assistantIds,
      dueAt: dueAt,
    ),
    'repairs.action.assigned',
  );

  Future<bool> diagnose({
    required String diagnosis,
    String? faultId,
    String? faultGroupId,
    String? resolutionType,
  }) => _run(
    () => repairs.diagnose(
      id,
      diagnosis: diagnosis,
      faultId: faultId,
      faultGroupId: faultGroupId,
      resolutionType: resolutionType,
    ),
    'repairs.action.diagnosed',
  );

  Future<bool> changeStatus(String status, String note) => _run(
    () => repairs.changeStatus(id, status, note),
    'repairs.action.statusChanged',
  );

  Future<bool> complete({
    required String resolutionSummary,
    String? postRepairWarrantyUntil,
    bool calibrationRequired = false,
    Map<String, dynamic>? proposeFault,
  }) => _run(
    () => repairs.complete(
      id,
      resolutionSummary: resolutionSummary,
      postRepairWarrantyUntil: postRepairWarrantyUntil,
      calibrationRequired: calibrationRequired,
      proposeFault: proposeFault,
    ),
    'repairs.action.completed',
  );

  Future<bool> acceptance({
    required bool accepted,
    num? rating,
    String? note,
  }) => _run(
    () =>
        repairs.acceptance(id, accepted: accepted, rating: rating, note: note),
    'repairs.action.acceptanceSaved',
  );

  Future<bool> close() =>
      _run(() => repairs.close(id), 'repairs.action.closed');

  Future<bool> cancel(String reason) =>
      _run(() => repairs.cancel(id, reason), 'repairs.action.cancelled');

  /// Thêm nhật ký: luôn vào outbox (offline-first, clientId idempotent) rồi gửi.
  Future<void> addLog({
    required String action,
    String? note,
    num? durationMinutes,
  }) async {
    final clientId = _uuid();
    await outbox.enqueue(RepairLogOutboxHandler.typeName, {
      'ticketId': id,
      'clientId': clientId,
      'at': DateTime.now().toUtc().toIso8601String(),
      'action': action,
      'note': ?note,
      'durationMinutes': ?durationMinutes,
    });
    await loadPendingLogs();
    final online = await outbox.run();
    if (!online) AppSnackbar.info('sync.offline'.tr);
    await loadPendingLogs();
    // Tải lại nhật ký server nếu đã gửi.
    if (online && pendingLogs.isEmpty) {
      try {
        final d = await repairs.detail(id);
        item.value = d;
        serverLogs.assignAll(d.logs);
      } catch (_) {
        // giữ dữ liệu hiện có
      }
    }
  }

  static String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Object().hashCode & 0xffff;
    return 'log-$now-$rand';
  }
}
