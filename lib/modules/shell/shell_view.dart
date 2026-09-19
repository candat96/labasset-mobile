import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../account/account_view.dart';
import '../home/home_view.dart';
import '../placeholder/placeholder_view.dart';
import 'shell_controller.dart';

/// Khung chính: 4 tab + FAB quét ở giữa.
class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final i = controller.index.value;
      return Scaffold(
        body: IndexedStack(
          index: i,
          children: const [
            HomeView(),
            PlaceholderView(keyName: 'repairs'),
            PlaceholderView(keyName: 'stock'),
            AccountView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'scan',
          tooltip: 'tab.scan'.tr,
          onPressed: () => Get.toNamed(Routes.scan),
          child: const Icon(Icons.qr_code_scanner),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'tab.home'.tr,
                index: 0,
                current: i,
              ),
              _NavItem(
                icon: Icons.build_outlined,
                label: 'tab.repairs'.tr,
                index: 1,
                current: i,
              ),
              const SizedBox(width: 64),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                label: 'tab.stock'.tr,
                index: 2,
                current: i,
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'tab.account'.tr,
                index: 3,
                current: i,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _NavItem extends GetView<ShellController> {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
  });

  final IconData icon;
  final String label;
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = index == current;
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => controller.select(index),
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
