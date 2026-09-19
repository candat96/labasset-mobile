import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import 'requests_list_controller.dart';

/// Danh sách phiếu yêu cầu (phía Vật tư).
class RequestsListView extends GetView<RequestsListController> {
  const RequestsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('requests.title'.tr),
        actions: [
          Obx(
            () =>
                controller.segment.value == RequestSegment.pending &&
                    controller.selected.isNotEmpty
                ? TextButton(
                    onPressed: () async {
                      final ok = await controller.approveBulk();
                      if (!ok) {
                        AppSnackbar.error(
                          controller.error.value ?? 'errors.UNKNOWN'.tr,
                        );
                      } else {
                        AppSnackbar.success('requests.approved'.tr);
                      }
                    },
                    child: Text(
                      '${'requests.approveBulk'.tr} (${controller.selected.length})',
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: SegmentedButton<RequestSegment>(
                segments: [
                  ButtonSegment(
                    value: RequestSegment.pending,
                    label: Text('requests.segment.pending'.tr),
                  ),
                  ButtonSegment(
                    value: RequestSegment.toIssue,
                    label: Text('requests.segment.toIssue'.tr),
                  ),
                  ButtonSegment(
                    value: RequestSegment.all,
                    label: Text('requests.segment.all'.tr),
                  ),
                ],
                selected: {controller.segment.value},
                onSelectionChanged: (s) => controller.setSegment(s.first),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
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
                  icon: Icons.description_outlined,
                  title: 'requests.empty'.tr,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final r = controller.items[i];
                    return Card(
                      child: ListTile(
                        leading:
                            controller.segment.value == RequestSegment.pending
                            ? Obx(
                                () => Checkbox(
                                  value: controller.selected.contains(r.id),
                                  onChanged: (_) =>
                                      controller.toggleSelect(r.id),
                                ),
                              )
                            : null,
                        title: Text('${r.code} — ${r.departmentName ?? ''}'),
                        subtitle: Text(
                          '${r.requesterName ?? ''}'
                          '${r.neededBy == null ? '' : ' · ${'requests.neededBy'.tr}: ${formatDate(r.neededBy)}'}'
                          ' · ${r.itemCount} ${'stock.issue.lines'.tr}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (r.priority == 'urgent')
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.xs,
                                ),
                                child: Text(
                                  'requests.urgent'.tr,
                                  style: TextStyle(
                                    color: context.status.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            StatusBadge(
                              tone: toneForRequestStatus(r.status),
                              label: 'status.request.${r.status}'.tr,
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Get.toNamed('/requests/${r.id}');
                          await controller.load();
                        },
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
