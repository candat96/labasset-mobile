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
                onPressed: () => _reject(controller),
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
              title: d.departmentName ?? d.departmentId,
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
                  d.requesterName ?? d.requesterId,
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
                    onPressed: () => _comment(controller),
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
                    onPressed: () => _reject(controller),
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
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'requests.approve'.tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final i in d.items) ...[
                Text(i.label, style: Get.theme.textTheme.labelLarge),
                Row(
                  children: [
                    Expanded(
                      child: QtyField(
                        controller: TextEditingController(
                          text: c.approvedQty[i.id] ?? i.qtyRequested,
                        ),
                        label: 'requests.qtyApproved'.tr,
                        onChanged: (v) => c.setApprovedQty(i.id, v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
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
                onPressed: () async {
                  final ok = await c.approve();
                  if (ok) Get.back();
                },
                child: Text('common.confirm'.tr),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
}

Future<void> _reject(RequestDetailController c) async {
  final reason = TextEditingController();
  await Get.dialog<void>(
    AlertDialog(
      title: Text('requests.reject'.tr),
      content: TextField(
        controller: reason,
        decoration: InputDecoration(labelText: 'requests.rejectReason'.tr),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
        FilledButton(
          onPressed: () async {
            if (reason.text.trim().isEmpty) return;
            Get.back();
            await c.reject(reason.text.trim());
          },
          child: Text('common.confirm'.tr),
        ),
      ],
    ),
  );
  reason.dispose();
}

Future<void> _issue(RequestDetailController c) async {
  await c.issue();
}

Future<void> _comment(RequestDetailController c) async {
  final body = TextEditingController();
  await Get.dialog<void>(
    AlertDialog(
      title: Text('requests.addComment'.tr),
      content: TextField(
        controller: body,
        maxLines: 3,
        decoration: InputDecoration(labelText: 'requests.comment'.tr),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
        FilledButton(
          onPressed: () async {
            final v = body.text;
            Get.back();
            await c.addComment(v);
          },
          child: Text('common.save'.tr),
        ),
      ],
    ),
  );
  body.dispose();
}
