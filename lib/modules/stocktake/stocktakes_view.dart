import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import 'stocktakes_controller.dart';

/// Danh sách đợt kiểm kê + tải dữ liệu về máy.
class StocktakesView extends GetView<StocktakesController> {
  const StocktakesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('stocktake.title'.tr)),
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
            icon: Icons.fact_check_outlined,
            title: 'stocktake.empty'.tr,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final s = controller.items[i];
              final meta = controller.metas[s.id];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${s.code} — ${s.name}',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          StatusBadge(
                            tone: s.status == 'counting'
                                ? StatusTone.info
                                : StatusTone.warning,
                            label: 'stocktake.status.${s.status}'.tr,
                          ),
                        ],
                      ),
                      Text(
                        '${'stocktake.type.${s.type}'.tr} · ${'stocktake.scope.${s.scopeType}'.tr}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(value: s.percent.clamp(0, 1)),
                      Text(
                        '${s.counted}/${s.total} (${(s.percent * 100).round()}%)',
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        meta == null
                            ? 'stocktake.notDownloaded'.tr
                            : 'stocktake.downloadedAt'.trParams({
                                'time': formatDateTime(meta.downloadedAt),
                              }),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: meta == null
                              ? context.status.warning
                              : context.status.success,
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => controller.download(s),
                            icon: const Icon(Icons.download_outlined, size: 18),
                            label: Text('stocktake.download'.tr),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (meta != null)
                            FilledButton.icon(
                              onPressed: () =>
                                  Get.toNamed(Routes.stocktakeCount(s.id)),
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: Text('stocktake.count'.tr),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
