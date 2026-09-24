import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/modules/shell/shell_controller.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('vai trò kho/VT thấy tab Kho', () {
    final c = ShellController(roles: const ['EQUIPMENT_STAFF']);
    expect(c.tabs, const [
      ShellTab.home,
      ShellTab.repairs,
      ShellTab.stock,
      ShellTab.account,
    ]);
    c.select(2);
    expect(c.current, ShellTab.stock);
  });

  test('trưởng khoa thấy tab Dự trù thay Kho', () {
    final c = ShellController(roles: const ['DEPT_HEAD']);
    expect(c.tabs, const [
      ShellTab.home,
      ShellTab.repairs,
      ShellTab.demand,
      ShellTab.account,
    ]);
    c.select(2);
    expect(c.current, ShellTab.demand);
  });

  test('nhân viên khoa (DEPT_USER) cũng thấy Dự trù, không có Kho', () {
    final c = ShellController(roles: const ['DEPT_USER']);
    expect(c.current, ShellTab.home);
    expect(c.tabs.contains(ShellTab.stock), isFalse);
    expect(c.tabs.contains(ShellTab.demand), isTrue);
  });

  test('select ngoài khoảng bị bỏ qua', () {
    final c = ShellController(roles: const ['HOSPITAL_ADMIN']);
    c.select(9);
    expect(c.index.value, 0);
    c.select(-1);
    expect(c.index.value, 0);
  });
}
