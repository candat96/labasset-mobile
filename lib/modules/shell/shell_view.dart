import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_buttons.dart';
import '../account/account_view.dart';
import '../home/home_view.dart';
import '../repairs/repairs_controller.dart';
import '../repairs/repairs_view.dart';
import '../stock/stock_overview_view.dart';
import 'shell_controller.dart';

/// Khung chính: bốn tab nội dung và một hành động quét ở giữa.
class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.index.value;
      return Scaffold(
        body: IndexedStack(
          index: index,
          children: const [
            HomeView(),
            RepairsView(),
            StockOverviewView(),
            AccountView(),
          ],
        ),
        floatingActionButton: switch (index) {
          1 => GradientFab(
            heroTag: 'repairNew',
            onPressed: _openRepair,
            icon: LucideIcons.triangleAlert,
            label: 'repairs.new'.tr,
          ),
          2 => GradientFab(
            heroTag: 'stockReceiptNew',
            onPressed: () => Get.toNamed(Routes.stockReceiptNew),
            icon: LucideIcons.packagePlus,
            label: 'stock.receipt.new'.tr,
          ),
          _ => null,
        },
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AppBottomNav(
          selectedIndex: index,
          onSelected: controller.select,
          centerIcon: LucideIcons.scanLine,
          centerLabel: 'tab.scan'.tr,
          onCenterTap: () => Get.toNamed(Routes.scan),
          items: [
            AppNavItem(icon: LucideIcons.house, label: 'tab.home'.tr),
            AppNavItem(
              icon: LucideIcons.wrench,
              label: 'tab.repairs'.tr,
              badge: _CountBadge(
                count: Get.find<RepairsController>().myOpenCount,
              ),
            ),
            AppNavItem(icon: LucideIcons.warehouse, label: 'tab.stock'.tr),
            AppNavItem(icon: LucideIcons.userRound, label: 'tab.account'.tr),
          ],
        ),
      );
    });
  }

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
        borderRadius: BorderRadius.circular(999),
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
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  });
}
