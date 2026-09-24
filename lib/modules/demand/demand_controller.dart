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
    this.isDept = false,
    DemandSegment initialSegment = DemandSegment.mine,
  }) : segment = initialSegment.obs;

  final DemandRepository demand;

  /// STAFF/ADM thấy tab "Kỳ"; khoa chỉ thấy phiếu của mình.
  final bool canSeePeriods;

  /// Trưởng khoa/nhân viên khoa: "Của tôi" luôn hiện phiếu khoa mình kể cả
  /// 0 dòng (phiếu do API tạo) — họ không lập phiếu trên app.
  final bool isDept;

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
        // Khoa: luôn hiện phiếu khoa mình (kể cả 0 dòng). VT/ADM: ẩn phiếu
        // rỗng do API tự tạo.
        mine.assignAll(isDept ? page.items : page.items.where(_isActionable));
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
