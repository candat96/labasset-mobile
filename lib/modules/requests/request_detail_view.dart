import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/qty_field.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/detail_widgets.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/request_detail.dart';
import 'request_detail_controller.dart';

/// Chi tiết phiếu yêu cầu + hành động duyệt/từ chối/cấp phát/bình luận.
class RequestDetailView extends GetView<RequestDetailController> {
  const RequestDetailView({super.key});

  @override
  String? get tag => Get.parameters['id'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.loading.value && controller.item.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('requests.title'.tr)),
          body: const LoadingList(),
        );
      }
      final err = controller.error.value;
      if (err != null && controller.item.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('requests.title'.tr)),
          body: ErrorState(error: err, onRetry: controller.load),
        );
      }
      final d = controller.item.value!;
      return Scaffold(
        appBar: AppBar(
          title: Text(d.code),
          actions: [
            if (controller.canApprove)
              IconButton(
                tooltip: 'requests.reject'.tr,
                icon: const Icon(LucideIcons.ban),
                onPressed: () => _reject(context, controller),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            DetailHeaderCard(
              margin: EdgeInsets.zero,
              icon: LucideIcons.fileCheck,
              title: d.departmentName ?? 'requests.departmentUnknown'.tr,
              code: d.code,
              badges: [
                StatusBadge(
                  tone: toneForRequestStatus(d.status),
                  label: 'status.request.${d.status}'.tr,
                ),
                if (d.priority == 'urgent')
                  StatusBadge(
                    tone: StatusTone.danger,
                    label: 'requests.urgent'.tr,
                  ),
              ],
              subtitle: '${'requests.reason'.tr}: ${d.reason}',
              stats: [
                DetailStat(
                  'requests.requester'.tr,
                  d.requesterName ?? 'requests.requesterUnknown'.tr,
                  icon: LucideIcons.userRound,
                ),
                if (d.neededBy != null)
                  DetailStat(
                    'requests.neededBy'.tr,
                    formatDate(d.neededBy),
                    icon: LucideIcons.calendarClock,
                  ),
              ],
              extra: d.rejectedReason == null
                  ? null
                  : Text(
                      '${'requests.rejectedReason'.tr}: ${d.rejectedReason}',
                      style: context.appText.label.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              title: 'requests.items'.tr,
              child: Column(
                children: [for (final i in d.items) _itemRow(context, i)],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              title: 'requests.comments'.tr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in d.comments)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.body, style: context.appText.body),
                      subtitle: Text(
                        [c.userName, formatRelative(c.createdAt)]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: context.appText.caption,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _comment(context, controller),
                    icon: const Icon(LucideIcons.messageSquarePlus, size: 18),
                    label: Text('requests.addComment'.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: controller.canApprove
            ? StickyActionBar(
                secondary: [
                  StickySecondaryButton(
                    label: 'requests.reject'.tr,
                    icon: LucideIcons.ban,
                    danger: true,
                    onPressed: () => _reject(context, controller),
                  ),
                ],
                primary: GradientButton(
                  label: 'requests.approve'.tr,
                  icon: LucideIcons.check,
                  onPressed: () => _approve(context, controller),
                ),
              )
            : controller.canIssue
            ? StickyActionBar(
                primary: GradientButton(
                  label: 'requests.issue'.tr,
                  icon: LucideIcons.packageMinus,
                  onPressed: () => _issue(controller),
                ),
              )
            : null,
      );
    });
  }

  Widget _itemRow(BuildContext context, RequestItem i) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(i.label, style: theme.textTheme.bodyMedium)),
              if (i.quotaExceeded)
                Text(
                  'requests.quotaExceeded'.tr,
                  style: TextStyle(color: context.status.warning),
                ),
            ],
          ),
          Text(
            '${'requests.qtyRequested'.tr}: ${i.qtyRequested}'
            ' · ${'requests.qtyApproved'.tr}: ${i.qtyApproved}'
            ' · ${'requests.qtyIssued'.tr}: ${i.qtyIssued}'
            '${i.shortage == '0' ? '' : ' · ${'requests.shortage'.tr}: ${i.shortage}'}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

Future<void> _approve(BuildContext context, RequestDetailController c) async {
  final d = c.item.value!;
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      initial: {
        for (final i in d.items)
          'qty:${i.id}': c.approvedQty[i.id] ?? i.qtyRequested,
      },
      builder: (context, form) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: 'requests.approve'.tr),
            for (final i in d.items) ...[
              Text(i.label, style: Theme.of(context).textTheme.labelLarge),
              Row(
                children: [
                  Expanded(
                    child: QtyField(
                      controller: form.field('qty:${i.id}'),
                      label: 'requests.qtyApproved'.tr,
                      onChanged: (v) => c.setApprovedQty(i.id, v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: form.field('note:${i.id}'),
                      decoration: InputDecoration(
                        labelText: 'requests.approverNote'.tr,
                      ),
                      onChanged: (v) => c.setApproverNote(i.id, v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            FilledButton(
              onPressed: form.busy
                  ? null
                  : () async {
                      form.setBusy(true);
                      final ok = await c.approve();
                      form.setBusy(false);
                      if (ok) form.close();
                    },
              child: Text('common.confirm'.tr),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _reject(BuildContext context, RequestDetailController c) async {
  final reason = await AppDialog.prompt(
    context,
    title: 'requests.reject'.tr,
    label: 'requests.rejectReason'.tr,
    confirmLabel: 'common.confirm'.tr,
  );
  if (reason == null || reason.isEmpty) return;
  await c.reject(reason);
}

Future<void> _issue(RequestDetailController c) async {
  await c.issue();
}

Future<void> _comment(BuildContext context, RequestDetailController c) async {
  await AppSheet.show<void>(
    context,
    builder: (_) => SheetForm(
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'requests.addComment'.tr),
          TextField(
            controller: form.field('body'),
            focusNode: form.focusNode('body'),
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'requests.comment'.tr,
              errorText: form.error('body'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: form.busy
                ? null
                : () async {
                    if (form.text('body').isEmpty) {
                      form.setError('body', 'common.required'.tr);
                      return;
                    }
                    form.setBusy(true);
                    final ok = await c.addComment(form.text('body'));
                    form.setBusy(false);
                    if (ok) form.close();
                  },
            child: Text('common.save'.tr),
          ),
        ],
      ),
    ),
  );
}
