import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import 'stock_overview_controller.dart';

/// Tab "Kho": cảnh báo + lối tắt nhập/xuất/chuyển/tra tồn.
class StockOverviewView extends GetView<StockOverviewController> {
  const StockOverviewView({super.key});

  static const _actions = [
    (key: 'lookup', icon: Icons.search),
    (key: 'receipt', icon: Icons.move_to_inbox_outlined),
    (key: 'issue', icon: Icons.outbox_outlined),
    (key: 'transfer', icon: Icons.swap_horiz_outlined),
    (key: 'pending', icon: Icons.pending_actions_outlined),
    (key: 'alerts', icon: Icons.notification_important_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('stock.title'.tr)),
      body: Obx(() {
        if (controller.loading.value &&
            controller.alertTotals.isEmpty &&
            controller.error.value == null) {
          return const LoadingList();
        }
        if (controller.error.value != null && controller.alertTotals.isEmpty) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TextField(
                controller: controller.search,
                textInputAction: TextInputAction.search,
                onSubmitted: (q) =>
                    Get.toNamed(Routes.stockLookup, arguments: {'q': q}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'stock.searchHint'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('stock.alerts'.tr, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final t in StockOverviewController.alertTypes)
                    SizedBox(
                      width: (MediaQuery.sizeOf(context).width - 44) / 2,
                      child: KpiTile(
                        label: 'stock.alert.$t'.tr,
                        value: '${controller.totalOf(t)}',
                        icon: Icons.warning_amber_outlined,
                        tone: controller.totalOf(t) > 0
                            ? switch (t) {
                                'expired' => StatusTone.danger,
                                'low_stock' => StatusTone.warning,
                                _ => StatusTone.info,
                              }
                            : StatusTone.success,
                        onTap: () => Get.toNamed(
                          Routes.placeholderFor('stockAlerts'),
                          arguments: {'type': t},
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('stock.shortcuts'.tr, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 2.4,
                children: [
                  for (final a in _actions)
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        onTap: () => _open(context, a.key),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Row(
                            children: [
                              Icon(a.icon, color: theme.colorScheme.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'stock.action.${a.key}'.tr,
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                              if (a.key == 'pending' &&
                                  controller.pendingIssue.value > 0)
                                Badge(
                                  label: Text(
                                    '${controller.pendingIssue.value}',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _open(BuildContext context, String key) async {
    switch (key) {
      case 'lookup':
        await Get.toNamed(Routes.stockLookup);
      case 'receipt':
        await Get.toNamed(Routes.stockReceipts);
      case 'issue':
        await Get.toNamed(Routes.placeholderFor('stockIssue'));
      case 'transfer':
        await Get.toNamed(Routes.placeholderFor('stockTransfer'));
      case 'pending':
        await Get.toNamed(Routes.placeholderFor('requests'));
      case 'alerts':
        await Get.toNamed(Routes.placeholderFor('stockAlerts'));
    }
  }
}
