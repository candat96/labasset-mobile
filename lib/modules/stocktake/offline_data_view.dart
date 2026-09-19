import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
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
            icon: Icons.storage_outlined,
            title: 'offline.empty'.tr,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.sessions.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final (meta, pending) = controller.sessions[i];
            return Card(
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
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(controller, meta, pending),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _confirmDelete(
    OfflineDataController c,
    dynamic meta,
    int pending,
  ) async {
    if (pending > 0) {
      await c.remove(meta);
      return;
    }
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('offline.deleteConfirm'.tr),
        content: Text(meta.name as String),
        actions: [
          TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('common.delete'.tr),
          ),
        ],
      ),
    );
    if (ok == true) await c.remove(meta);
  }
}
