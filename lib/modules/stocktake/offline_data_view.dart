import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/app_card.dart';
import 'offline_data_controller.dart';

/// Quản lý dữ liệu offline (trong Cá nhân).
class OfflineDataView extends GetView<OfflineDataController> {
  const OfflineDataView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('offline.title'.tr)),
      body: Obx(() {
        if (controller.loading.value) return const LoadingList();
        if (controller.error.value != null) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.sessions.isEmpty) {
          return EmptyState(
            icon: LucideIcons.database,
            title: 'offline.empty'.tr,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.sessions.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final (meta, pending) = controller.sessions[i];
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text('${meta.code} — ${meta.name}'),
                subtitle: Text(
                  '${'offline.downloadedAt'.tr}: ${formatDateTime(meta.downloadedAt)}'
                  '\n${'offline.pending'.tr}: $pending',
                  style: theme.textTheme.bodySmall,
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'common.delete'.tr,
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () =>
                      _confirmDelete(context, controller, meta, pending),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OfflineDataController c,
    dynamic meta,
    int pending,
  ) async {
    if (pending > 0) {
      await c.remove(meta);
      return;
    }
    final ok = await ConfirmSheet.show(
      context,
      title: 'offline.deleteConfirm'.tr,
      description: meta.name as String,
      confirmLabel: 'common.delete'.tr,
      destructive: true,
    );
    if (ok) await c.remove(meta);
  }
}
