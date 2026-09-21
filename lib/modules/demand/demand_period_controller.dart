import 'package:get/get.dart';

import '../../data/models/demand.dart';
import '../../data/repositories/demand_repository.dart';

enum DemandPeriodSegment { requests, consolidation }

/// Chi tiết kỳ dự trù (STAFF/ADM): KPI + phiếu khoa + bảng tổng hợp chỉ đọc.
class DemandPeriodController extends GetxController {
  DemandPeriodController({required this.demand, required this.id});

  final DemandRepository demand;
  final String id;

  final Rxn<DemandPeriod> period = Rxn<DemandPeriod>();
  final Rxn<DemandSummary> summary = Rxn<DemandSummary>();
  final RxList<DemandRequestSummary> requests = <DemandRequestSummary>[].obs;
  final RxList<DemandConsolidation> consolidation = <DemandConsolidation>[].obs;
  final Rx<DemandPeriodSegment> segment = DemandPeriodSegment.requests.obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  /// departmentId → tên khoa (để hiện breakdown tổng hợp).
  final Map<String, String> deptNames = {};

  bool get showConsolidation => const [
    'consolidating',
    'approved',
    'closed',
  ].contains(period.value?.status);

  DemandProgress? get progress => period.value?.progress;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void setSegment(DemandPeriodSegment s) => segment.value = s;

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      period.value = await demand.period(id);
      final results = await Future.wait<Object>([
        demand.summary(id),
        demand.periodRequests(id, limit: 50),
      ]);
      summary.value = results[0] as DemandSummary;
      final reqPage = results[1] as DemandRequestSummaryPage;
      requests.assignAll(reqPage.items);
      deptNames
        ..clear()
        ..addEntries(
          reqPage.items
              .where((r) => r.departmentId != null)
              .map((r) => MapEntry(r.departmentId!, r.departmentName ?? '')),
        );
      if (showConsolidation) {
        consolidation.assignAll(await demand.consolidation(id));
      } else {
        consolidation.clear();
      }
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  String deptName(String? departmentId) =>
      deptNames[departmentId] ?? 'demand.department'.tr;
}
