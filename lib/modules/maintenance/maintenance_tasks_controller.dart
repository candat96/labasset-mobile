import 'package:get/get.dart';

import '../../data/models/maintenance.dart';
import '../../data/models/task.dart';
import '../../data/repositories/tasks_repository.dart';

/// Danh sách công việc bảo dưỡng `/maintenance/tasks`.
class MaintenanceTasksController extends GetxController {
  MaintenanceTasksController({required this.tasks, this.userId = ''});

  final TasksRepository tasks;
  final String userId;

  final RxBool mineOnly = true.obs;
  final RxnString statusFilter = RxnString();
  final RxnString typeFilter = RxnString();
  final RxList<MaintenanceTask> items = <MaintenanceTask>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final page = await tasks.list(
        assigneeId: mineOnly.value && userId.isNotEmpty ? 'me' : null,
        status: statusFilter.value,
        type: typeFilter.value,
        limit: 30,
      );
      items.assignAll(page.items.map(_toTask));
      total.value = page.total.toInt();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void setMineOnly(bool v) {
    mineOnly.value = v;
    load();
  }

  void setStatus(String? s) {
    statusFilter.value = s;
    load();
  }

  void setType(String? t) {
    typeFilter.value = t;
    load();
  }

  /// TaskSummary → MaintenanceTask (list không có templateItems).
  MaintenanceTask _toTask(TaskSummary t) => MaintenanceTask(
    id: t.id,
    code: t.code,
    equipmentId: t.equipmentId,
    type: t.type,
    scheduledAt: t.scheduledAt,
    dueAt: t.dueAt,
    assigneeId: t.assigneeId,
    status: t.status,
  );
}
