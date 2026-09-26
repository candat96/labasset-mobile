import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_buttons.dart';
import '../account/account_view.dart';
import '../demand/demand_view.dart';
import '../home/home_view.dart';
import '../repairs/repairs_controller.dart';
import '../repairs/repairs_view.dart';
import '../stock/stock_overview_view.dart';
import 'shell_controller.dart';

/// Khung chính: bốn tab nội dung (động theo vai trò) và một hành động quét ở
/// giữa. Kho/VT thấy Kho + FAB nhập kho; khoa thấy Dự trù thay cho Kho.
class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabs = controller.tabs;
      final index = controller.index.value.clamp(0, tabs.length - 1).toInt();
      return Scaffold(
        body: IndexedStack(
          index: index,
          children: [for (final tab in tabs) _page(tab)],
        ),
        floatingActionButton: _fab(tabs[index]),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AppBottomNav(
          selectedIndex: index,
          onSelected: controller.select,
          centerIcon: LucideIcons.scanLine,
          centerLabel: 'tab.scan'.tr,
          onCenterTap: () => Get.toNamed(Routes.scan),
          items: [for (final tab in tabs) _navItem(tab)],
        ),
      );
    });
  }

  Widget _page(ShellTab tab) => switch (tab) {
    ShellTab.home => const HomeView(),
    ShellTab.repairs => const RepairsView(),
    ShellTab.stock => const StockOverviewView(),
    ShellTab.demand => const DemandView(),
    ShellTab.account => const AccountView(),
  };

  AppNavItem _navItem(ShellTab tab) => switch (tab) {
    ShellTab.home => AppNavItem(icon: LucideIcons.house, label: 'tab.home'.tr),
    ShellTab.repairs => AppNavItem(
      icon: LucideIcons.wrench,
      label: 'tab.repairs'.tr,
      badge: _CountBadge(count: Get.find<RepairsController>().myOpenCount),
    ),
    ShellTab.stock => AppNavItem(
      icon: LucideIcons.warehouse,
      label: 'tab.stock'.tr,
    ),
    ShellTab.demand => AppNavItem(
      icon: LucideIcons.clipboardList,
      label: 'tab.demand'.tr,
    ),
    ShellTab.account => AppNavItem(
      icon: LucideIcons.userRound,
      label: 'tab.account'.tr,
    ),
  };

  Widget? _fab(ShellTab tab) => switch (tab) {
    ShellTab.repairs => GradientFab(
      heroTag: 'repairNew',
      onPressed: _openRepair,
      icon: LucideIcons.triangleAlert,
      label: 'repairs.new'.tr,
    ),
    ShellTab.stock => GradientFab(
      heroTag: 'stockReceiptNew',
      onPressed: () => Get.toNamed(Routes.stockReceiptNew),
      icon: LucideIcons.packagePlus,
      label: 'stock.receipt.new'.tr,
    ),
    _ => null,
  };

  Future<void> _openRepair() async {
    final id = (await Get.toNamed(Routes.repairNew)) as String?;
    if (id != null) await Get.toNamed(Routes.repair(id));
    await Get.find<RepairsController>().load();
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final RxInt count;

  @override
  Widget build(BuildContext context) => Obx(() {
    final value = count.value;
    if (value <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: context.status.danger,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        value > 99 ? '99+' : '$value',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onError,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  });
}
