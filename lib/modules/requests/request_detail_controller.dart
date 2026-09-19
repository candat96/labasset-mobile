import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/request_detail.dart';
import '../../data/repositories/requests_repository.dart';

/// Chi tiết phiếu yêu cầu: duyệt (chỉnh số lượng), từ chối, cấp phát, bình luận.
class RequestDetailController extends GetxController {
  RequestDetailController({
    required this.requests,
    required this.id,
    Future<void> Function(String route)? navigate,
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r));

  final RequestsRepository requests;
  final String id;
  final Future<void> Function(String route) _navigate;

  final Rxn<RequestDetail> item = Rxn<RequestDetail>();
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  /// Số lượng duyệt theo dòng (itemId → chuỗi).
  final RxMap<String, String> approvedQty = <String, String>{}.obs;
  final RxMap<String, String> approverNotes = <String, String>{}.obs;

  bool get canApprove {
    final s = item.value?.status;
    return s == 'submitted' || s == 'dept_approved';
  }

  bool get canIssue {
    final s = item.value?.status;
    return s == 'approved' || s == 'partially_approved';
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
      final d = await requests.detail(id);
      item.value = d;
      approvedQty.clear();
      for (final i in d.items) {
        approvedQty[i.id] = i.qtyRequested;
      }
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void setApprovedQty(String itemId, String qty) => approvedQty[itemId] = qty;

  void setApproverNote(String itemId, String note) =>
      approverNotes[itemId] = note;

  Future<bool> approve() async {
    final d = item.value;
    if (d == null) return false;
    try {
      await requests.approve(
        id,
        items: [
          for (final i in d.items)
            (
              itemId: i.id,
              qtyApproved: approvedQty[i.id] ?? i.qtyRequested,
              note: approverNotes[i.id],
            ),
        ],
      );
      AppSnackbar.success('requests.approved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<bool> reject(String reason) async {
    try {
      await requests.reject(id, reason);
      AppSnackbar.success('requests.rejected'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  /// Cấp phát → mở phiếu xuất draft điền sẵn.
  Future<bool> issue({String? warehouseId}) async {
    try {
      final issueId = await requests.issue(id, warehouseId: warehouseId);
      AppSnackbar.success('requests.issued'.tr);
      await load();
      if (issueId != null) {
        await _navigate('/stock/issues/$issueId');
      }
      return true;
    } catch (e) {
      final code = ApiError.from(e).code;
      if (code == 'STOCK_INSUFFICIENT') {
        AppSnackbar.error(e);
      } else {
        AppSnackbar.error(e);
      }
      return false;
    }
  }

  Future<void> addComment(String body) async {
    if (body.trim().isEmpty) return;
    try {
      await requests.addComment(id, body.trim());
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }
}
