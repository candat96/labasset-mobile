import 'package:get/get.dart';

import '../../data/models/demand.dart';
import '../../data/repositories/demand_repository.dart';

enum DemandSegment { mine, periods }

/// Danh sách dự trù: **Của tôi** (`/v1/demand/my`) và **Kỳ**
/// (`/v1/demand/periods`, chỉ STAFF/ADM).
class DemandController extends GetxController {
  DemandController({
    required this.demand,
    this.canSeePeriods = true,
    DemandSegment initialSegment = DemandSegment.mine,
  }) : segment = initialSegment.obs;

  final DemandRepository demand;

  /// STAFF/ADM thấy tab "Kỳ"; khoa chỉ thấy phiếu của mình.
  final bool canSeePeriods;

  final Rx<DemandSegment> segment;
  final RxList<DemandRequest> mine = <DemandRequest>[].obs;
  final RxList<DemandPeriod> periods = <DemandPeriod>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void setSegment(DemandSegment s) {
    if (segment.value == s) return;
    segment.value = s;
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      if (segment.value == DemandSegment.mine) {
        final page = await demand.my(limit: 50);
        mine.assignAll(page.items.where(_isActionable));
      } else {
        final page = await demand.periods(limit: 50);
        periods.assignAll(page.items);
      }
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  /// Ẩn phiếu rỗng do API tự tạo (draft/accepted không có dòng) cho VT/ADM.
  static bool _isActionable(DemandRequest r) =>
      r.lines.isNotEmpty ||
      const ['submitted', 'dept_approved', 'returned'].contains(r.status);
}
