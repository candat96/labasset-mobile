import 'package:get/get.dart';

import '../../data/models/request.dart';
import '../../data/repositories/requests_repository.dart';

enum RequestSegment { pending, toIssue, all }

/// Danh sách phiếu yêu cầu phía Vật tư.
class RequestsListController extends GetxController {
  RequestsListController({required this.requests, this.isAdmin = false});

  final RequestsRepository requests;
  final bool isAdmin;

  final Rx<RequestSegment> segment = RequestSegment.pending.obs;
  final RxList<RequestSummary> items = <RequestSummary>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxSet<String> selected = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void setSegment(RequestSegment s) {
    segment.value = s;
    selected.clear();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final page = switch (segment.value) {
        RequestSegment.pending => await requests.list(
          pendingForMe: true,
          limit: 30,
        ),
        RequestSegment.toIssue => await requests.list(
          status: 'approved,partially_approved',
          limit: 30,
        ),
        RequestSegment.all => await requests.list(limit: 30),
      };
      items.assignAll(page.items);
      total.value = page.total.toInt();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void toggleSelect(String id) {
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
  }

  Future<bool> approveBulk() async {
    if (selected.isEmpty) return false;
    try {
      await requests.approveBulk(selected.toList());
      selected.clear();
      await load();
      return true;
    } catch (e) {
      error.value = e;
      return false;
    }
  }
}
