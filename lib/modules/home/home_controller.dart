import 'package:get/get.dart';

import '../../core/storage/session_store.dart';
import '../../data/repositories/settings_repository.dart';

class HomeStat {
  const HomeStat(this.key, this.value, this.route);
  final String key;
  final int value;
  final String route;
}

class HomeShortcut {
  const HomeShortcut(this.key, this.icon, this.route);
  final String key;
  final int icon; // codePoint của Icons (để const)
  final String route;
}

/// Trang chủ. Số liệu "việc của tôi"/"cảnh báo" là MOCK có nhãn — chờ API tổng hợp.
class HomeController extends GetxController {
  HomeController({required this.store, required this.settings});

  final SessionStore store;
  final SettingsRepository settings;

  final RxnString hospitalName = RxnString();
  final bool isMock = true;

  // TODO(api): thay bằng API "việc của tôi hôm nay" + cảnh báo khi backend có.
  final List<HomeStat> myTasks = const [
    HomeStat('home.task.repairsAssigned', 3, '/placeholder/repairs'),
    HomeStat('home.task.maintenanceDue', 2, '/placeholder/maintenance'),
    HomeStat('home.task.stocktakesOpen', 1, '/placeholder/stocktake'),
  ];
  final List<HomeStat> alerts = const [
    HomeStat('home.alert.brokenUnassigned', 1, '/placeholder/repairs'),
    HomeStat('home.alert.suppliesLow', 7, '/placeholder/stock'),
    HomeStat('home.alert.calibrationOverdue', 2, '/placeholder/maintenance'),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadHospitalName();
  }

  Future<void> _loadHospitalName() async {
    try {
      hospitalName.value = await settings.hospitalName();
    } catch (_) {
      // best-effort
    }
  }
}
