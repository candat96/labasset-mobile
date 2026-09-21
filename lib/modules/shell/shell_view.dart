import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
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
          1 => FloatingActionButton.extended(
            heroTag: 'repairNew',
            onPressed: _openRepair,
            icon: const Icon(LucideIcons.triangleAlert),
            label: Text('repairs.new'.tr),
          ),
          2 => FloatingActionButton.extended(
            heroTag: 'stockReceiptNew',
            onPressed: () => Get.toNamed(Routes.stockReceiptNew),
            icon: const Icon(LucideIcons.packagePlus),
            label: Text('stock.receipt.new'.tr),
          ),
          _ => null,
        },
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
          selectedIndex: switch (index) {
            0 => 0,
            1 => 1,
            2 => 3,
            _ => 4,
          },
          onDestinationSelected: (destination) async {
            if (destination == 2) {
              await Get.toNamed(Routes.scan);
              return;
            }
            controller.select(switch (destination) {
              0 => 0,
              1 => 1,
              3 => 2,
              _ => 3,
            });
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(LucideIcons.house),
              selectedIcon: const Icon(LucideIcons.house),
              label: 'tab.home'.tr,
            ),
            NavigationDestination(
              icon: _RepairNavIcon(
                count: Get.find<RepairsController>().myOpenCount,
              ),
              selectedIcon: _RepairNavIcon(
                count: Get.find<RepairsController>().myOpenCount,
              ),
              label: 'tab.repairs'.tr,
            ),
            NavigationDestination(
              icon: _ScanNavIcon(label: 'tab.scan'.tr),
              selectedIcon: _ScanNavIcon(label: 'tab.scan'.tr),
              label: 'tab.scan'.tr,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.warehouse),
              selectedIcon: const Icon(LucideIcons.warehouse),
              label: 'tab.stock'.tr,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.userRound),
              selectedIcon: const Icon(LucideIcons.userRound),
              label: 'tab.account'.tr,
            ),
          ],
        ),
      );
    });
  }

  Future<void> _openRepair() async {
    final id = await Get.toNamed<String>(Routes.repairNew);
    if (id != null) await Get.toNamed(Routes.repair(id));
    await Get.find<RepairsController>().load();
  }
}

class _ScanNavIcon extends StatelessWidget {
  const _ScanNavIcon({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        LucideIcons.scanLine,
        size: 24,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
  );
}

class _RepairNavIcon extends StatelessWidget {
  const _RepairNavIcon({required this.count});
  final RxInt count;

  @override
  Widget build(BuildContext context) => Obx(() {
    final value = count.value;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(LucideIcons.wrench, size: 24),
        if (value > 0)
          Positioned(
            right: -9,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: context.status.danger,
                borderRadius: BorderRadius.circular(999),
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
            ),
          ),
      ],
    );
  });
}
