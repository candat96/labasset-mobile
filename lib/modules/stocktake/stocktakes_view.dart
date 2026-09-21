import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/large_title_scaffold.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import 'stocktakes_controller.dart';

/// Danh sách đợt kiểm kê + tải dữ liệu về máy.
class StocktakesView extends GetView<StocktakesController> {
  const StocktakesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LargeTitleScaffold(
      title: 'stocktake.title'.tr,
      body: Obx(() {
        if (controller.loading.value && controller.items.isEmpty) {
          return const LoadingList();
        }
        if (controller.error.value != null && controller.items.isEmpty) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.items.isEmpty) {
          return EmptyState(
            icon: LucideIcons.clipboardCheck,
            title: 'stocktake.empty'.tr,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl * 2,
            ),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final s = controller.items[i];
              final meta = controller.metas[s.id];
              final tone = s.status == 'counting'
                  ? StatusTone.info
                  : StatusTone.warning;
              return ListItemCard(
                code: s.code,
                badge: StatusBadge(
                  tone: tone,
                  label: 'stocktake.status.${s.status}'.tr,
                ),
                title: s.name,
                accentColor: paletteForTone(context, tone).color,
                showChevron: false,
                metas: [
                  ListMeta(
                    LucideIcons.layers,
                    '${'stocktake.type.${s.type}'.tr} · ${'stocktake.scope.${s.scopeType}'.tr}',
                  ),
                  ListMeta(
                    meta == null
                        ? LucideIcons.cloudOff
                        : LucideIcons.cloudCheck,
                    meta == null
                        ? 'stocktake.notDownloaded'.tr
                        : 'stocktake.downloadedAt'.trParams({
                            'time': formatDateTime(meta.downloadedAt),
                          }),
                    color: meta == null
                        ? context.status.warning
                        : context.status.success,
                  ),
                ],
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      child: LinearProgressIndicator(
                        value: s.percent.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${s.counted}/${s.total} (${(s.percent * 100).round()}%)',
                      style: context.appText.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            onPressed: () => controller.download(s),
                            icon: const Icon(LucideIcons.download, size: 18),
                            label: Text('stocktake.download'.tr),
                          ),
                        ),
                        if (meta != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 44),
                              ),
                              onPressed: () =>
                                  Get.toNamed(Routes.stocktakeCount(s.id)),
                              icon: const Icon(
                                LucideIcons.pencilLine,
                                size: 18,
                              ),
                              label: Text('stocktake.count'.tr),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
