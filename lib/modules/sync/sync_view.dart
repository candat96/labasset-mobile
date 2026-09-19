import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import 'sync_controller.dart';

class SyncView extends GetView<SyncController> {
  const SyncView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('sync.title'.tr),
        actions: [
          IconButton(
            tooltip: 'sync.retry'.tr,
            icon: const Icon(Icons.refresh),
            onPressed: controller.load,
          ),
        ],
      ),
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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => StatusBadge(
                        tone: controller.outbox.pending.value == 0
                            ? StatusTone.success
                            : StatusTone.warning,
                        label:
                            '${'sync.pending'.tr}: ${controller.outbox.pending.value}',
                      ),
                    ),
                  ),
                  Obx(
                    () => StatusBadge(
                      tone: controller.outbox.failed.value == 0
                          ? StatusTone.success
                          : StatusTone.danger,
                      label:
                          '${'sync.failed'.tr}: ${controller.outbox.failed.value}',
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.retryAll,
                    icon: const Icon(Icons.replay),
                    label: Text('sync.retry'.tr),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.runNow,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text('sync.runNow'.tr),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            Expanded(
              child: controller.items.isEmpty
                  ? EmptyState(
                      icon: Icons.cloud_done_outlined,
                      title: 'sync.empty'.tr,
                    )
                  : RefreshIndicator(
                      onRefresh: controller.load,
                      child: ListView.separated(
                        itemCount: controller.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final item = controller.items[i];
                          final typeKey = 'sync.type.${item.type}';
                          final typeLabel = typeKey.tr;
                          return ListTile(
                            leading: Icon(
                              item.attempts > 0
                                  ? Icons.error_outline
                                  : Icons.schedule,
                              color: item.attempts > 0
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                            title: Text(
                              typeLabel == typeKey ? item.type : typeLabel,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formatDateTime(item.createdAt)),
                                Text(
                                  '${'sync.attempts'.tr}: ${item.attempts}'
                                  '${item.lastError == null || item.lastError!.isEmpty ? '' : ' · ${'sync.lastError'.tr}: ${item.lastError}'}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: Text(formatRelative(item.createdAt)),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}
