import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/repair.dart';
import '../../data/repositories/repairs_repository.dart';

enum RepairsSegment { mine, unassigned, all }

/// Danh sách sửa chữa: segment Của tôi / Chưa phân công / Tất cả + lọc + phân trang.
class RepairsController extends GetxController {
  RepairsController({
    required this.repairs,
    this.userId = '',
    RepairsSegment initialSegment = RepairsSegment.mine,
  }) : segment = initialSegment.obs;

  final RepairsRepository repairs;
  final String userId;

  static const openStatuses =
      'accepted,in_progress,awaiting_parts,awaiting_vendor';

  final Rx<RepairsSegment> segment;
  final RxSet<String> statuses = <String>{}.obs;
  final RxnString severity = RxnString();
  final RxnString departmentId = RxnString();
  final RxBool overdue = false.obs;
  final RxBool filterActive = false.obs;

  final RxList<RepairSummary> items = <RepairSummary>[].obs;
  final RxInt total = 0.obs;
  final RxInt myOpenCount = 0.obs;
  final RxBool loading = true.obs;
  final RxBool loadingMore = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void setSegment(RepairsSegment s) {
    if (segment.value == s) return;
    segment.value = s;
    load();
  }

  void applyFilters({
    Set<String>? statuses,
    String? severity,
    String? departmentId,
    bool? overdue,
  }) {
    if (statuses != null) this.statuses.assignAll(statuses);
    this.severity.value = severity;
    this.departmentId.value = departmentId;
    if (overdue != null) this.overdue.value = overdue;
    filterActive.value =
        this.statuses.isNotEmpty ||
        this.severity.value != null ||
        this.departmentId.value != null ||
        this.overdue.value;
    load();
  }

  String? get _statusParam {
    switch (segment.value) {
      case RepairsSegment.mine:
        return statuses.isEmpty ? openStatuses : statuses.join(',');
      case RepairsSegment.unassigned:
        return statuses.isEmpty ? 'new' : statuses.join(',');
      case RepairsSegment.all:
        return statuses.isEmpty ? null : statuses.join(',');
    }
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    _page = 1;
    try {
      final page = await repairs.list(
        assigneeId: segment.value == RepairsSegment.mine ? 'me' : null,
        status: _statusParam,
        severity: severity.value,
        departmentId: departmentId.value,
        overdue: overdue.value ? true : null,
        limit: 20,
      );
      items.assignAll(page.items);
      total.value = page.total.toInt();
      unawaited(loadMyOpenCount());
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMyOpenCount() async {
    try {
      final page = await repairs.list(
        assigneeId: 'me',
        status: openStatuses,
        limit: 1,
      );
      myOpenCount.value = page.total.toInt();
    } catch (_) {
      // badge best-effort
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value || items.length >= total.value) return;
    loadingMore.value = true;
    try {
      final page = await repairs.list(
        assigneeId: segment.value == RepairsSegment.mine ? 'me' : null,
        status: _statusParam,
        severity: severity.value,
        departmentId: departmentId.value,
        overdue: overdue.value ? true : null,
        page: _page + 1,
        limit: 20,
      );
      _page += 1;
      items.addAll(page.items);
      total.value = page.total.toInt();
    } catch (_) {
      // giữ danh sách hiện tại
    } finally {
      loadingMore.value = false;
    }
  }
}
