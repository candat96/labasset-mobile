import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/detail_widgets.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/demand.dart';
import 'demand_request_controller.dart';

const _itemTypeOrder = ['supply', 'component', 'equipment', 'service'];

/// Phiếu dự trù khoa: header + dòng chỉ đọc nhóm theo loại hàng + thanh
/// hành động dính đáy (duyệt/trả lại/tiếp nhận).
class DemandRequestView extends GetView<DemandRequestController> {
  const DemandRequestView({super.key});

  @override
  String? get tag => Get.parameters['id'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final d = controller.item.value;
      if (controller.loading.value && d == null) {
        return Scaffold(
          appBar: AppBar(title: Text('demand.title'.tr)),
          body: const LoadingList(),
        );
      }
      final err = controller.error.value;
      if (err != null && d == null) {
        return Scaffold(
          appBar: AppBar(title: Text('demand.title'.tr)),
          body: ErrorState(error: err, onRetry: controller.load),
        );
      }
      final req = d!;
      return Scaffold(
        appBar: AppBar(title: Text(req.period?.code ?? 'demand.title'.tr)),
        body: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            _header(context, req),
            for (final type in _itemTypeOrder)
              if (_linesOf(req, type).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: SectionCard(
                    title: 'demand.itemType.$type'.tr,
                    child: Column(
                      children: [
                        for (final l in _linesOf(req, type))
                          _LineTile(
                            line: l,
                            showApproved: controller.showApprovedQty,
                          ),
                      ],
                    ),
                  ),
                ),
            if (req.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'demand.periodRequestsEmpty'.tr,
                  textAlign: TextAlign.center,
                  style: context.appText.label,
                ),
              ),
          ],
        ),
        bottomNavigationBar: _actionBar(context, req),
      );
    });
  }

  List<DemandLine> _linesOf(DemandRequest req, String type) =>
      req.lines.where((l) => l.itemType == type).toList();

  Widget _header(BuildContext context, DemandRequest req) {
    final d = req;
    return DetailHeaderCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      icon: LucideIcons.clipboardList,
      title: d.department?.name ?? 'demand.department'.tr,
      code: d.period?.code,
      badges: [
        StatusBadge(
          tone: toneForDemandRequestStatus(d.status),
          label: 'status.demandRequest.${d.status}'.tr,
        ),
      ],
      subtitle: d.period?.name,
      stats: [
        if (d.creator?.fullName != null)
          DetailStat(
            'demand.creator'.tr,
            d.creator!.fullName,
            icon: LucideIcons.userRound,
          ),
        DetailStat(
          'demand.lineCount'.tr,
          '${d.lines.length}',
          icon: LucideIcons.listChecks,
        ),
        DetailStat(
          'demand.totalEstimated'.tr,
          formatVnd(d.totalEstimated),
          icon: LucideIcons.wallet,
        ),
      ],
      extra: d.returnReason == null
          ? null
          : _ReturnBanner(reason: d.returnReason!),
    );
  }

  Widget? _actionBar(BuildContext context, DemandRequest req) {
    if (controller.canAccept) {
      return StickyActionBar(
        secondary: [
          StickySecondaryButton(
            label: 'demand.reject'.tr,
            icon: LucideIcons.undo2,
            danger: true,
            onPressed: () => _return(context),
          ),
        ],
        primary: GradientButton(
          label: 'demand.accept'.tr,
          icon: LucideIcons.packageCheck,
          onPressed: () => _accept(context),
        ),
      );
    }
    if (controller.canDeptApprove) {
      return StickyActionBar(
        secondary: [
          StickySecondaryButton(
            label: 'demand.reject'.tr,
            icon: LucideIcons.undo2,
            danger: true,
            onPressed: () => _return(context),
          ),
        ],
        primary: GradientButton(
          label: 'demand.approve'.tr,
          icon: LucideIcons.check,
          onPressed: () => _approve(context),
        ),
      );
    }
    return null;
  }

  Future<void> _approve(BuildContext context) async {
    final ok = await ConfirmSheet.show(
      context,
      title: 'demand.approveConfirm'.tr,
      description: 'demand.approveConfirmDesc'.tr,
      confirmLabel: 'demand.approve'.tr,
    );
    if (ok) await controller.deptApprove();
  }

  Future<void> _accept(BuildContext context) async {
    final ok = await ConfirmSheet.show(
      context,
      title: 'demand.acceptConfirm'.tr,
      description: 'demand.acceptConfirmDesc'.tr,
      confirmLabel: 'demand.accept'.tr,
    );
    if (ok) await controller.accept();
  }

  Future<void> _return(BuildContext context) async {
    await AppSheet.show<void>(
      context,
      builder: (_) => SheetForm(
        builder: (context, form) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: 'demand.returnTitle'.tr),
            TextField(
              controller: form.field('reason'),
              focusNode: form.focusNode('reason'),
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'demand.returnHint'.tr,
                errorText: form.error('reason'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: form.busy
                  ? null
                  : () async {
                      final reason = form.text('reason');
                      if (reason.isEmpty) {
                        form.setError('reason', 'common.required'.tr);
                        return;
                      }
                      form.setBusy(true);
                      final ok = await controller.returnRequest(reason);
                      form.setBusy(false);
                      if (ok) form.close();
                    },
              child: Text('demand.reject'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnBanner extends StatelessWidget {
  const _ReturnBanner({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForTone(context, StatusTone.warning);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.undo2, size: 18, color: palette.color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${'demand.returnReason'.tr}: $reason',
              style: context.appText.label.copyWith(color: palette.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line, required this.showApproved});
  final DemandLine line;
  final bool showApproved;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    final theme = Theme.of(context);
    final approved = line.qtyApproved;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.supplyCode == null
                      ? line.itemName
                      : '${line.itemName} · ${line.supplyCode}',
                  style: text.bodyStrong,
                ),
              ),
              if (line.priority != 'normal') ...[
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  tone: line.priority == 'urgent'
                      ? StatusTone.danger
                      : StatusTone.warning,
                  label: 'demand.priority.${line.priority}'.tr,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (line.unit != null) '${'demand.line.unit'.tr}: ${line.unit}',
              '${'demand.line.qtyRequested'.tr}: ${line.qtyRequested}',
              '${'demand.line.unitPrice'.tr}: ${formatVnd(line.unitPriceEst)}',
              '${'demand.line.amount'.tr}: ${formatVnd(line.amountEst)}',
            ].join(' · '),
            style: text.label,
          ),
          if (showApproved && approved != null) ...[
            const SizedBox(height: 2),
            Text(
              '${'demand.line.qtyApproved'.tr}: $approved',
              style: text.label.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (line.reason != null && line.reason!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${'demand.line.reason'.tr}: ${line.reason}',
              style: text.caption,
            ),
          ],
          if (line.suggestion != null) ...[
            const SizedBox(height: 2),
            Text(
              '${'demand.line.suggested'.tr}: '
              '${line.suggestedQty ?? line.suggestion!.avgMonthly}'
              ' · ${'demand.line.onHand'.tr}: ${line.suggestion!.onHand}',
              style: text.caption,
            ),
          ],
        ],
      ),
    );
  }
}
