import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';

/// Mục trong khung chính. Danh sách tab là **động** theo vai trò: kho/VT thấy
/// Kho, khoa thấy Dự trù; vì vậy index không được hardcode 0..3.
enum ShellTab { home, repairs, stock, demand, account }

/// Tab theo vai trò: Kho (kho/VT) hoặc Dự trù (khoa) ở vị trí thứ ba.
List<ShellTab> shellTabsFor(List<String> roles) {
  final warehouse = roles.any(Routes.warehouseRoles.contains);
  return [
    ShellTab.home,
    ShellTab.repairs,
    warehouse ? ShellTab.stock : ShellTab.demand,
    ShellTab.account,
  ];
}

class ShellController extends GetxController {
  ShellController({List<String>? roles}) : roles = roles ?? _sessionRoles();

  /// Vai trò người dùng hiện tại (truyền vào để test, mặc định đọc phiên).
  final List<String> roles;

  List<ShellTab> get tabs => shellTabsFor(roles);

  final RxInt index = 0.obs;

  /// Tab đang chọn; kẹp trong khoảng hợp lệ phòng khi danh sách tab đổi.
  ShellTab get current {
    final i = index.value.clamp(0, tabs.length - 1).toInt();
    return tabs[i];
  }

  void select(int i) {
    if (i < 0 || i >= tabs.length) return;
    index.value = i;
  }

  static List<String> _sessionRoles() {
    if (!Get.isRegistered<SessionStore>()) return const [];
    return Get.find<SessionStore>().user.value?.roles ?? const [];
  }
}
