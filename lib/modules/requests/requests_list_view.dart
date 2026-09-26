import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/large_title_scaffold.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/segment_tabs.dart';
import '../../core/widgets/status_badge.dart';
import 'requests_list_controller.dart';

/// Danh sách phiếu yêu cầu (phía Vật tư).
class RequestsListView extends GetView<RequestsListController> {
  const RequestsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return LargeTitleScaffold(
      title: 'requests.title'.tr,
      actions: [
        Obx(
          () =>
              controller.segment.value == RequestSegment.pending &&
                  controller.selected.isNotEmpty
              ? AppButton.success(
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
                  label:
                      '${'requests.approveBulk'.tr} (${controller.selected.length})',
                )
              : const SizedBox.shrink(),
        ),
      ],
      header: Obx(
        () => SegmentTabs<RequestSegment>(
          tabs: [
            SegmentTab(
              value: RequestSegment.pending,
              label: 'requests.segment.pending'.tr,
            ),
            SegmentTab(
              value: RequestSegment.toIssue,
              label: 'requests.segment.toIssue'.tr,
            ),
            SegmentTab(
              value: RequestSegment.all,
              label: 'requests.segment.all'.tr,
            ),
          ],
          selected: controller.segment.value,
          onChanged: controller.setSegment,
        ),
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
        if (controller.items.isEmpty) {
          return EmptyState(
            icon: LucideIcons.fileCheck,
            title: 'requests.empty'.tr,
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
              final r = controller.items[i];
              final urgent = r.priority == 'urgent';
              return ListItemCard(
                code: r.code,
                badge: StatusBadge(
                  tone: toneForRequestStatus(r.status),
                  label: 'status.request.${r.status}'.tr,
                ),
                title: r.departmentName ?? r.code,
                accentColor: urgent
                    ? context.status.danger
                    : paletteForTone(
                        context,
                        toneForRequestStatus(r.status),
                      ).color,
                leading: controller.segment.value == RequestSegment.pending
                    ? Obx(
                        () => Checkbox(
                          value: controller.selected.contains(r.id),
                          onChanged: (_) => controller.toggleSelect(r.id),
                        ),
                      )
                    : null,
                metas: [
                  if (r.requesterName != null && r.requesterName!.isNotEmpty)
                    ListMeta(LucideIcons.userRound, r.requesterName!),
                  if (r.neededBy != null)
                    ListMeta(
                      LucideIcons.calendarClock,
                      '${'requests.neededBy'.tr}: ${formatDate(r.neededBy)}',
                    ),
                  ListMeta(
                    LucideIcons.listChecks,
                    '${r.itemCount} ${'stock.issue.lines'.tr}',
                  ),
                  if (urgent)
                    ListMeta(
                      LucideIcons.flame,
                      'requests.urgent'.tr,
                      color: context.status.danger,
                    ),
                ],
                onTap: () async {
                  await Get.toNamed('/requests/${r.id}');
                  await controller.load();
                },
              );
            },
          ),
        );
      }),
    );
  }
}
