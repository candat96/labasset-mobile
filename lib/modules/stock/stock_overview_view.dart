import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/shortcut_tile.dart';
import '../../core/widgets/status_badge.dart';
import 'stock_overview_controller.dart';

/// Tab "Kho": cảnh báo + lối tắt nhập/xuất/chuyển/tra tồn.
class StockOverviewView extends GetView<StockOverviewController> {
  const StockOverviewView({super.key});

  static const _actions = [
    (key: 'lookup', icon: LucideIcons.search),
    (key: 'receipt', icon: LucideIcons.packagePlus),
    (key: 'issue', icon: LucideIcons.packageMinus),
    (key: 'transfer', icon: LucideIcons.arrowLeftRight),
    (key: 'pending', icon: LucideIcons.clock3),
    (key: 'alerts', icon: LucideIcons.bellRing),
  ];

  @override
  Widget build(BuildContext context) {
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
                  prefixIcon: const Icon(LucideIcons.search),
                  hintText: 'stock.searchHint'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'stock.alerts'.tr,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final t in StockOverviewController.alertTypes)
                      SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 76) / 2,
                        child: KpiTile(
                          label: 'stock.alert.$t'.tr,
                          value: '${controller.totalOf(t)}',
                          icon: LucideIcons.triangleAlert,
                          tone: controller.totalOf(t) > 0
                              ? switch (t) {
                                  'expired' => StatusTone.danger,
                                  'low_stock' => StatusTone.warning,
                                  _ => StatusTone.info,
                                }
                              : StatusTone.success,
                          onTap: () => Get.toNamed(
                            Routes.stockAlerts,
                            arguments: {'type': t},
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'stock.shortcuts'.tr,
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.05,
                  children: [
                    for (final action in _actions)
                      ShortcutTile(
                        icon: action.icon,
                        label: 'stock.action.${action.key}'.tr,
                        onTap: () => _open(context, action.key),
                      ),
                  ],
                ),
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
        await Get.toNamed(Routes.stockIssues);
      case 'transfer':
        await Get.toNamed(Routes.stockTransferNew);
      case 'pending':
        await Get.toNamed('${Routes.requests}?segment=toIssue');
      case 'alerts':
        await Get.toNamed(Routes.stockAlerts);
    }
  }
}
