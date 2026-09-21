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
import '../../core/widgets/segment_tabs.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/demand.dart';
import 'demand_controller.dart';

/// Danh sách dự trù: tab Của tôi (phiếu khoa) + Kỳ (STAFF/ADM).
class DemandView extends GetView<DemandController> {
  const DemandView({super.key});

  @override
  Widget build(BuildContext context) {
    return LargeTitleScaffold(
      title: 'demand.title'.tr,
      header: controller.canSeePeriods
          ? Obx(
              () => SegmentTabs<DemandSegment>(
                tabs: [
                  SegmentTab(
                    value: DemandSegment.mine,
                    label: 'demand.segment.mine'.tr,
                  ),
                  SegmentTab(
                    value: DemandSegment.periods,
                    label: 'demand.segment.periods'.tr,
                  ),
                ],
                selected: controller.segment.value,
                onChanged: controller.setSegment,
              ),
            )
          : null,
      body: Obx(() {
        if (controller.loading.value &&
            controller.mine.isEmpty &&
            controller.periods.isEmpty) {
          return const LoadingList();
        }
        final err = controller.error.value;
        if (err != null) {
          return ErrorState(error: err, onRetry: controller.load);
        }
        return controller.segment.value == DemandSegment.mine
            ? _MineList(controller: controller)
            : _PeriodList(controller: controller);
      }),
    );
  }
}

class _MineList extends StatelessWidget {
  const _MineList({required this.controller});
  final DemandController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.mine.isEmpty) {
      return EmptyState(
        icon: LucideIcons.clipboardList,
        title: 'demand.myEmpty'.tr,
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
        itemCount: controller.mine.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          final r = controller.mine[i];
          return ListItemCard(
            code: r.period?.code,
            badge: StatusBadge(
              tone: toneForDemandRequestStatus(r.status),
              label: 'status.demandRequest.${r.status}'.tr,
            ),
            title: r.period?.name ?? r.department?.name ?? 'demand.title'.tr,
            accentColor: paletteForTone(
              context,
              toneForDemandRequestStatus(r.status),
            ).color,
            metas: [
              if (r.department?.name != null)
                ListMeta(LucideIcons.building2, r.department!.name),
              ListMeta(
                LucideIcons.listChecks,
                '${r.lines.length} ${'demand.lines'.tr}',
              ),
              if (r.totalEstimated != '0')
                ListMeta(
                  LucideIcons.wallet,
                  '${'demand.totalEstimated'.tr}: '
                  '${formatVnd(r.totalEstimated)}',
                ),
            ],
            onTap: () async {
              await Get.toNamed(Routes.demandRequest(r.id));
              await controller.load();
            },
          );
        },
      ),
    );
  }
}

class _PeriodList extends StatelessWidget {
  const _PeriodList({required this.controller});
  final DemandController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.periods.isEmpty) {
      return EmptyState(
        icon: LucideIcons.calendarRange,
        title: 'demand.empty'.tr,
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
        itemCount: controller.periods.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          final p = controller.periods[i];
          final overdue =
              p.submitDeadline != null &&
              (DateTime.tryParse(p.submitDeadline!)?.isBefore(DateTime.now()) ??
                  false);
          return ListItemCard(
            code: p.code,
            badge: StatusBadge(
              tone: toneForDemandPeriodStatus(p.status),
              label: 'status.demandPeriod.${p.status}'.tr,
            ),
            title: p.name,
            accentColor: paletteForTone(
              context,
              toneForDemandPeriodStatus(p.status),
            ).color,
            metas: [
              ListMeta(LucideIcons.layers, 'demand.kind.${p.kind}'.tr),
              if (p.submitDeadline != null)
                ListMeta(
                  LucideIcons.calendarClock,
                  '${'demand.deadline'.tr}: ${formatDate(p.submitDeadline)}',
                  color: overdue ? context.status.danger : null,
                ),
            ],
            footer: p.progress == null
                ? null
                : _ProgressBar(progress: p.progress!),
            onTap: () => Get.toNamed(Routes.demandPeriod(p.id)),
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final DemandProgress progress;

  @override
  Widget build(BuildContext context) {
    final total = progress.total.toInt();
    final submitted = progress.submitted.toInt();
    final value = total == 0 ? 0.0 : (submitted / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: context.isDark
                ? AppColors.segmentDark
                : AppColors.segment,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'demand.progressText'.trParams({
            'submitted': '$submitted',
            'total': '$total',
          }),
          style: context.appText.caption,
        ),
      ],
    );
  }
}
