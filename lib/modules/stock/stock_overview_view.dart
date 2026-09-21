import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/large_title_scaffold.dart';
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
    final tileWidth = (MediaQuery.sizeOf(context).width - 44) / 2;
    return LargeTitleScaffold(
      title: 'stock.title'.tr,
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl * 3,
            ),
            children: [
              AppCard(
                radius: AppRadius.chip,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: controller.search,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (q) => Get.toNamed(
                            Routes.stockLookup,
                            arguments: {'q': q},
                          ),
                          style: context.appText.body,
                          decoration: InputDecoration(
                            hintText: 'stock.searchHint'.tr,
                            hintStyle: context.appText.body.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            filled: false,
                            isCollapsed: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: SectionTitle('stock.alerts'.tr),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final t in StockOverviewController.alertTypes)
                    KpiTile(
                      width: tileWidth,
                      label: 'stock.alert.$t'.tr,
                      value: '${controller.totalOf(t)}',
                      icon: switch (t) {
                        'expired' => LucideIcons.calendarX,
                        'low_stock' => LucideIcons.packageMinus,
                        _ => LucideIcons.triangleAlert,
                      },
                      tone: switch (t) {
                        'expired' => StatusTone.danger,
                        'low_stock' => StatusTone.warning,
                        _ => StatusTone.info,
                      },
                      onTap: () => Get.toNamed(
                        Routes.stockAlerts,
                        arguments: {'type': t},
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: SectionTitle('stock.shortcuts'.tr),
              ),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                childAspectRatio: 1.25,
                children: [
                  for (final action in _actions)
                    ShortcutTile(
                      icon: action.icon,
                      label: 'stock.action.${action.key}'.tr,
                      onTap: () => _open(context, action.key),
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
