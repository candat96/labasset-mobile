import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../data/models/kpi.dart';
import '../../data/repositories/kpi_repository.dart';

/// Tab trong màn Hiệu suất: điểm của tôi / bảng toàn viện (chỉ ADM).
enum KpiTab { mine, hospital }

/// Một chỉ số trong bảng (khối lượng/đúng hạn/tốc độ/chất lượng).
typedef KpiMetric = ({String key, num? value});

/// Điều khiển màn "Hiệu suất của tôi": đổi kỳ, tải điểm cá nhân + 6 kỳ,
/// danh sách việc hoàn tất; tab Toàn viện (chỉ đọc) cho quản trị viện.
class KpiController extends GetxController {
  KpiController({
    required this.repo,
    this.userId = '',
    this.isAdmin = false,
    String initialType = 'month',
    Future<void> Function(String route)? navigate,
  }) : periodType = initialType.obs,
       _navigate = navigate ?? ((r) async => Get.toNamed(r));

  final KpiRepository repo;

  /// Người đang đăng nhập (lấy danh sách việc hoàn tất qua `/users/:id`).
  final String userId;

  /// Quản trị viện: thêm tab Toàn viện (chỉ đọc, không chốt kỳ).
  final bool isAdmin;

  final Future<void> Function(String route) _navigate;

  final RxString periodType;
  final Rx<KpiTab> tab = KpiTab.mine.obs;
  final RxString area = 'repair'.obs;

  final Rxn<KpiPerson> score = Rxn<KpiPerson>();
  final RxList<KpiPoint> history = <KpiPoint>[].obs;
  final RxList<KpiTaskItem> tasks = <KpiTaskItem>[].obs;

  final Rxn<KpiBoard> board = Rxn<KpiBoard>();
  final RxList<KpiStaffRow> staff = <KpiStaffRow>[].obs;
  final Rxn<KpiTotals> totals = Rxn<KpiTotals>();

  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  static const areas = ['repair', 'maintenance', 'calibration'];

  List<KpiTab> get tabs =>
      isAdmin ? const [KpiTab.mine, KpiTab.hospital] : const [KpiTab.mine];

  /// Hạng chỉ hiện khi API trả về (cài đặt `staffCanSeeRanking` bật).
  bool get showRank => score.value?.rank != null;

  KpiAreaScore? get selectedArea => score.value?.areas.area(area.value);

  /// Bốn chỉ số của mảng đang chọn; chỉ số thiếu dữ liệu bị bỏ.
  List<KpiMetric> get metricRows {
    final a = selectedArea;
    if (a == null) return const [];
    return [
      (key: 'volume', value: a.volume),
      (key: 'onTime', value: a.onTime),
      (key: 'speed', value: a.speed),
      (key: 'quality', value: a.quality),
    ].where((m) => m.value != null).toList();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> setPeriodType(String type) async {
    if (periodType.value == type) return;
    periodType.value = type;
    await load();
  }

  Future<void> setTab(KpiTab value) async {
    if (tab.value == value) return;
    tab.value = value;
    await load();
  }

  void setArea(String name) => area.value = name;

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      if (tab.value == KpiTab.hospital) {
        final b = await repo.board(type: periodType.value);
        board.value = b;
        staff.assignAll(b.staff);
        totals.value = b.totals;
      } else {
        final person = await repo.me(type: periodType.value);
        score.value = person;
        history.assignAll(person.periods);
        _pickDefaultArea(person);
        if (userId.isEmpty) {
          tasks.clear();
        } else {
          final detail = await repo.user(
            userId,
            type: periodType.value,
            limit: 50,
          );
          tasks.assignAll(detail.tasks?.items ?? const []);
        }
      }
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  /// Mảng có nhiều đầu việc nhất; hoà thì theo thứ tự SC → BD → KĐ.
  void _pickDefaultArea(KpiPerson person) {
    var best = areas.first;
    var bestItems = -1;
    for (final name in areas) {
      final items = (person.areas.area(name)?.items ?? 0).toInt();
      if (items > bestItems) {
        bestItems = items;
        best = name;
      }
    }
    area.value = best;
  }

  /// Mở đầu việc hoàn tất: sửa chữa/bảo dưỡng có màn chi tiết, kiểm định mở danh sách.
  Future<void> openTask(KpiTaskItem item) async {
    await _navigate(switch (item.area) {
      'repair' => Routes.repair(item.id),
      'maintenance' => Routes.maintenanceTask(item.id),
      'calibration' => Routes.calibrations,
      _ => Routes.kpi,
    });
  }

  /// Chi tiết một người (chỉ đọc) cho tab Toàn viện.
  Future<KpiPerson> loadUser(String id, {int page = 1, int limit = 50}) =>
      repo.user(id, type: periodType.value, page: page, limit: limit);
}
