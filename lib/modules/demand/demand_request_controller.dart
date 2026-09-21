import 'dart:async';

import 'package:get/get.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../data/models/demand.dart';
import '../../data/repositories/demand_repository.dart';
import '../home/home_controller.dart';

/// Chi tiết phiếu dự trù khoa: xem dòng + duyệt/trả lại/tiếp nhận.
class DemandRequestController extends GetxController {
  DemandRequestController({
    required this.demand,
    required this.id,
    this.isDeptHead = false,
    this.isStaff = false,
    this.isAdmin = false,
    Future<void> Function(String route)? navigate,
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r));

  final DemandRepository demand;
  final String id;
  final bool isDeptHead;
  final bool isStaff;
  final bool isAdmin;
  final Future<void> Function(String route) _navigate;

  final Rxn<DemandRequest> item = Rxn<DemandRequest>();
  final RxBool loading = true.obs;
  final RxBool busy = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  String get status => item.value?.status ?? '';

  /// Trưởng khoa (hoặc ADM) duyệt phiếu đang chờ.
  bool get canDeptApprove => status == 'submitted' && (isDeptHead || isAdmin);

  /// VT/ADM tiếp nhận phiếu đã được trưởng khoa duyệt.
  bool get canAccept => status == 'dept_approved' && (isStaff || isAdmin);

  /// Trả lại: khoa trả khi `submitted`, VT/ADM trả khi `dept_approved`.
  bool get canReturn =>
      (status == 'submitted' && (isDeptHead || isAdmin)) ||
      (status == 'dept_approved' && (isStaff || isAdmin));

  bool get showApprovedQty =>
      (isStaff || isAdmin) &&
      const ['submitted', 'dept_approved', 'accepted'].contains(status);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      item.value = await demand.request(id);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> deptApprove() => _run(() async {
    await demand.deptApprove(id);
    AppSnackbar.success('demand.approved'.tr);
  });

  Future<bool> returnRequest(String reason) => _run(() async {
    await demand.returnRequest(id, reason.trim());
    AppSnackbar.success('demand.returned'.tr);
  });

  /// Tiếp nhận toàn bộ theo số lượng yêu cầu (không chỉnh từng dòng trên app).
  Future<bool> accept() => _run(() async {
    await demand.accept(id);
    AppSnackbar.success('demand.accepted'.tr);
  });

  Future<bool> _run(Future<void> Function() action) async {
    busy.value = true;
    try {
      await action();
      await load();
      _refreshHome();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    } finally {
      busy.value = false;
    }
  }

  /// Cập nhật lại "Việc của tôi" ở trang chủ (nếu đang mở).
  void _refreshHome() {
    if (Get.isRegistered<HomeController>()) {
      unawaited(Get.find<HomeController>().load());
    }
  }

  /// Điều hướng kỳ của phiếu (dùng ở header).
  Future<void> openPeriod() async {
    final periodId = item.value?.periodId;
    if (periodId != null && periodId.isNotEmpty) {
      await _navigate('/demand/periods/$periodId');
    }
  }
}
