import 'dart:async';

import 'package:get/get.dart';

import '../../core/cache/kv_cache.dart';
import '../../core/storage/session_store.dart';
import '../../data/models/repair.dart';
import '../../data/models/request.dart';
import '../../data/models/task.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/repairs_repository.dart';
import '../../data/repositories/requests_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/tasks_repository.dart';

/// Trang chủ: "Việc của tôi hôm nay" + cảnh báo ghép từ API, cache khi offline.
class HomeController extends GetxController {
  HomeController({
    required this.store,
    required this.settings,
    required this.repairs,
    required this.tasks,
    required this.requests,
    required this.equipment,
    required this.stock,
    this.cache,
  });

  final SessionStore store;
  final SettingsRepository settings;
  final RepairsRepository repairs;
  final TasksRepository tasks;
  final RequestsRepository requests;
  final EquipmentRepository equipment;
  final StockRepository stock;
  final KvCache? cache;

  static const cacheKey = 'home.snapshot';

  final RxnString hospitalName = RxnString();
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final Rxn<DateTime> cachedAt = Rxn<DateTime>();

  final RxList<RepairSummary> repairsAssigned = <RepairSummary>[].obs;
  final RxInt repairsAssignedTotal = 0.obs;
  final RxList<TaskSummary> tasksDue = <TaskSummary>[].obs;
  final RxInt tasksDueTotal = 0.obs;
  final RxList<RequestSummary> requestsPending = <RequestSummary>[].obs;
  final RxInt requestsPendingTotal = 0.obs;
  final RxList<RequestSummary> requestsApproved = <RequestSummary>[].obs;
  final RxInt requestsApprovedTotal = 0.obs;

  final RxInt brokenUnassigned = 0.obs;
  final RxInt suppliesAlert = 0.obs;
  final RxInt calibrationOverdue = 0.obs;

  /// Kiểm kê đang mở — API `/v1/stocktakes` chưa có (C3 đang làm) → ẩn nhóm.
  bool get hasStocktakeApi => false;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    Object? firstError;
    var ok = 0;

    Future<void> run(Future<void> Function() job) async {
      try {
        await job();
        ok++;
      } catch (e) {
        firstError ??= e;
      }
    }

    final list = <Future<void>>[];
    list.add(
      run(() async {
        final page = await repairs.list(
          assigneeId: 'me',
          status: 'accepted,in_progress,awaiting_parts,awaiting_vendor',
          limit: 3,
        );
        repairsAssigned.assignAll(page.items);
        repairsAssignedTotal.value = page.total.toInt();
      }),
    );
    list.add(
      run(() async {
        final page = await tasks.list(
          assigneeId: 'me',
          status: 'scheduled,overdue',
          to: _plusDays(7),
          limit: 3,
        );
        tasksDue.assignAll(page.items);
        tasksDueTotal.value = page.total.toInt();
      }),
    );
    list.add(
      run(() async {
        final page = await requests.list(pendingForMe: true, limit: 3);
        requestsPending.assignAll(page.items);
        requestsPendingTotal.value = page.total.toInt();
      }),
    );
    list.add(
      run(() async {
        final page = await requests.list(
          status: 'approved,partially_approved',
          limit: 3,
        );
        requestsApproved.assignAll(page.items);
        requestsApprovedTotal.value = page.total.toInt();
      }),
    );
    list.add(
      run(() async {
        final page = await repairs.list(status: 'new', limit: 1);
        brokenUnassigned.value = page.total.toInt();
      }),
    );
    list.add(
      run(() async {
        final page = await stock.alerts(resolved: false, limit: 1);
        suppliesAlert.value = page.total.toInt();
      }),
    );
    list.add(
      run(() async {
        calibrationOverdue.value = (await equipment.count(
          calibrationOverdue: true,
        )).toInt();
      }),
    );
    await Future.wait(list);

    if (ok == 0) {
      error.value = firstError;
      await _loadCache();
    } else {
      cachedAt.value = null;
      unawaited(_saveCache());
    }
    loading.value = false;
  }

  static String _plusDays(int days) =>
      DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();

  Map<String, dynamic> _snapshot() => {
    'repairsAssigned': repairsAssigned.map((e) => e.toJson()).toList(),
    'repairsAssignedTotal': repairsAssignedTotal.value,
    'tasksDue': tasksDue.map((e) => e.toJson()).toList(),
    'tasksDueTotal': tasksDueTotal.value,
    'requestsPending': requestsPending.map((e) => e.toJson()).toList(),
    'requestsPendingTotal': requestsPendingTotal.value,
    'requestsApproved': requestsApproved.map((e) => e.toJson()).toList(),
    'requestsApprovedTotal': requestsApprovedTotal.value,
    'brokenUnassigned': brokenUnassigned.value,
    'suppliesAlert': suppliesAlert.value,
    'calibrationOverdue': calibrationOverdue.value,
  };

  Future<void> _saveCache() async {
    try {
      await cache?.put(cacheKey, _snapshot());
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _loadCache() async {
    try {
      final cached = await cache?.get(cacheKey);
      if (cached == null) return;
      final d = cached.value;
      repairsAssigned.assignAll(
        _items(d['repairsAssigned'], RepairSummary.fromJson),
      );
      repairsAssignedTotal.value =
          (d['repairsAssignedTotal'] as num?)?.toInt() ?? 0;
      tasksDue.assignAll(_items(d['tasksDue'], TaskSummary.fromJson));
      tasksDueTotal.value = (d['tasksDueTotal'] as num?)?.toInt() ?? 0;
      requestsPending.assignAll(
        _items(d['requestsPending'], RequestSummary.fromJson),
      );
      requestsPendingTotal.value =
          (d['requestsPendingTotal'] as num?)?.toInt() ?? 0;
      requestsApproved.assignAll(
        _items(d['requestsApproved'], RequestSummary.fromJson),
      );
      requestsApprovedTotal.value =
          (d['requestsApprovedTotal'] as num?)?.toInt() ?? 0;
      brokenUnassigned.value = (d['brokenUnassigned'] as num?)?.toInt() ?? 0;
      suppliesAlert.value = (d['suppliesAlert'] as num?)?.toInt() ?? 0;
      calibrationOverdue.value =
          (d['calibrationOverdue'] as num?)?.toInt() ?? 0;
      cachedAt.value = cached.updatedAt;
    } catch (_) {
      // cache hỏng → coi như không có
    }
  }

  static List<T> _items<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}
