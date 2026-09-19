import 'package:get/get.dart';

import '../../data/models/repair.dart';
import '../../data/repositories/repairs_repository.dart';
import '../../data/repositories/tasks_repository.dart';

/// Thống kê việc của tôi trong tháng (Cá nhân).
class MyStatsController extends GetxController {
  MyStatsController({required this.repairs, required this.tasks});

  final RepairsRepository repairs;
  final TasksRepository tasks;

  final RxInt completed = 0.obs;
  final RxInt overdue = 0.obs;
  final RxInt maintenanceDone = 0.obs;
  final RxnDouble avgRating = RxnDouble();
  final RxBool loading = true.obs;

  /// TODO(api): chưa có endpoint thống kê — tính client từ ≤ 50 phiếu gần nhất.
  static const ratingSampleSize = 10;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final from = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    ).toUtc().toIso8601String();
    try {
      final done = await repairs.list(
        assigneeId: 'me',
        status: 'completed,acceptance,closed',
        from: from,
        limit: 50,
      );
      completed.value = done.total.toInt();
      avgRating.value = await _avgRating(done.items);
    } catch (_) {}
    try {
      overdue.value = (await repairs.list(
        assigneeId: 'me',
        overdue: true,
        limit: 1,
      )).total.toInt();
    } catch (_) {}
    try {
      maintenanceDone.value = (await tasks.list(
        assigneeId: 'me',
        status: 'done',
        from: from,
        limit: 1,
      )).total.toInt();
    } catch (_) {}
    loading.value = false;
  }

  Future<double?> _avgRating(List<RepairSummary> items) async {
    final sample = items.take(ratingSampleSize).toList();
    final ratings = <num>[];
    for (final r in sample) {
      try {
        final d = await repairs.detail(r.id);
        if (d.rating != null) ratings.add(d.rating!);
      } catch (_) {
        // bỏ qua phiếu lỗi
      }
    }
    if (ratings.isEmpty) return null;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}
