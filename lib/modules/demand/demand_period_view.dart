import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/segment_tabs.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/demand.dart';
import 'demand_period_controller.dart';

/// Chi tiết kỳ dự trù: KPI + phiếu khoa + bảng tổng hợp (chỉ đọc).
class DemandPeriodView extends GetView<DemandPeriodController> {
  const DemandPeriodView({super.key});

  @override
  String? get tag => Get.parameters['id'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.period.value;
      if (controller.loading.value && p == null) {
        return Scaffold(
          appBar: AppBar(title: Text('demand.title'.tr)),
          body: const LoadingList(),
        );
      }
      final err = controller.error.value;
      if (err != null && p == null) {
        return Scaffold(
          appBar: AppBar(title: Text('demand.title'.tr)),
          body: ErrorState(error: err, onRetry: controller.load),
        );
      }
      final period = p!;
      return Scaffold(
        appBar: AppBar(
          title: Text(period.code),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Center(
                child: StatusBadge(
                  tone: toneForDemandPeriodStatus(period.status),
                  label: 'status.demandPeriod.${period.status}'.tr,
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _header(context, period),
              const SizedBox(height: AppSpacing.md),
              _kpis(context),
              if (controller.showConsolidation) ...[
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => SegmentTabs<DemandPeriodSegment>(
                    tabs: [
                      SegmentTab(
                        value: DemandPeriodSegment.requests,
                        label: 'demand.segment.requests'.tr,
                      ),
                      SegmentTab(
                        value: DemandPeriodSegment.consolidation,
                        label: 'demand.segment.consolidation'.tr,
                      ),
                    ],
                    selected: controller.segment.value,
                    onChanged: controller.setSegment,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (!controller.showConsolidation ||
                  controller.segment.value == DemandPeriodSegment.requests)
                _requests(context)
              else
                _consolidation(context),
            ],
          ),
        ),
      );
    });
  }

  Widget _header(BuildContext context, DemandPeriod period) {
    final overdue =
        period.submitDeadline != null &&
        (DateTime.tryParse(period.submitDeadline!)?.isBefore(DateTime.now()) ??
            false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(period.name, style: context.appText.title),
        const SizedBox(height: 4),
        Text(
          [
            'demand.kind.${period.kind}'.tr,
            if (period.submitDeadline != null)
              '${'demand.deadline'.tr}: ${formatDate(period.submitDeadline)}',
          ].join(' · '),
          style: context.appText.label.copyWith(
            color: overdue ? context.status.danger : null,
          ),
        ),
        if (period.notes != null && period.notes!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(period.notes!, style: context.appText.caption),
        ],
      ],
    );
  }

  Widget _kpis(BuildContext context) {
    final s = controller.summary.value;
    return Row(
      children: [
        Expanded(
          child: KpiTile(
            width: double.infinity,
            height: 104,
            label: 'demand.departmentsSubmitted'.tr,
            value:
                '${s?.departmentsSubmitted.toInt() ?? 0}/'
                '${s?.departmentsTotal.toInt() ?? 0}',
            icon: LucideIcons.building2,
            accent: AppAccent.indigo,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: KpiTile(
            width: double.infinity,
            height: 104,
            label: 'demand.totalRequested'.tr,
            value: formatMoneyCompact(s?.totalRequested),
            icon: LucideIcons.wallet,
            accent: AppAccent.brand,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: KpiTile(
            width: double.infinity,
            height: 104,
            label: 'demand.totalApproved'.tr,
            value: formatMoneyCompact(s?.totalApproved),
            icon: LucideIcons.badgeCheck,
            accent: AppAccent.green,
          ),
        ),
      ],
    );
  }

  Widget _requests(BuildContext context) {
    if (controller.requests.isEmpty) {
      return EmptyState(
        icon: LucideIcons.fileStack,
        title: 'demand.periodRequestsEmpty'.tr,
      );
    }
    return Column(
      children: [
        for (final r in controller.requests) ...[
          ListItemCard(
            code: r.departmentCode,
            badge: StatusBadge(
              tone: toneForDemandRequestStatus(r.status),
              label: 'status.demandRequest.${r.status}'.tr,
            ),
            title: r.departmentName ?? 'demand.department'.tr,
            accentColor: paletteForTone(
              context,
              toneForDemandRequestStatus(r.status),
            ).color,
            metas: [
              ListMeta(
                LucideIcons.listChecks,
                '${r.lineCount.toInt()} ${'demand.lines'.tr}',
              ),
              if (r.totalEstimated != '0')
                ListMeta(
                  LucideIcons.wallet,
                  '${'demand.totalEstimated'.tr}: '
                  '${formatVnd(r.totalEstimated)}',
                ),
            ],
            onTap: () async {
              await Get.toNamed(Routes.demandRequest(r.requestId));
              await controller.load();
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _consolidation(BuildContext context) {
    if (controller.consolidation.isEmpty) {
      return EmptyState(
        icon: LucideIcons.table,
        title: 'demand.consolidationEmpty'.tr,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'demand.consolidationNote'.tr,
            style: context.appText.caption,
          ),
        ),
        for (final c in controller.consolidation) ...[
          ListItemCard(
            code: c.supplyCode,
            badge: StatusBadge(
              tone: toneForDemandDecision(c.decision),
              label: 'demand.decision.${c.decision}'.tr,
            ),
            title: c.itemName,
            accentColor: paletteForTone(
              context,
              toneForDemandDecision(c.decision),
            ).color,
            metas: [
              if (c.unit != null) ListMeta(LucideIcons.ruler, c.unit!),
              ListMeta(
                LucideIcons.arrowRightLeft,
                '${'demand.line.qtyRequested'.tr}: ${c.qtyRequested}'
                ' → ${'demand.line.qtyApproved'.tr}: ${c.qtyApproved}',
              ),
              ListMeta(
                LucideIcons.wallet,
                '${'demand.line.amount'.tr}: ${formatVnd(c.amountPlan)}',
              ),
            ],
            onTap: () => _showBreakdown(context, c),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Future<void> _showBreakdown(
    BuildContext context,
    DemandConsolidation c,
  ) async {
    await AppSheet.show<void>(
      context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'demand.breakdown'.tr),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(c.itemName, style: context.appText.bodyStrong),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                for (final b in c.breakdown)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.deptName(b.departmentId),
                            style: context.appText.body,
                          ),
                        ),
                        Text(
                          '${b.qtyRequested} → ${b.qtyApproved}',
                          style: context.appText.label.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
