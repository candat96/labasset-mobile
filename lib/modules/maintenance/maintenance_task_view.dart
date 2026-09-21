import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/pdf_file_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/detail_widgets.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/maintenance.dart';
import '../../data/repositories/tasks_repository.dart';
import 'maintenance_task_controller.dart';

/// Chi tiết công việc bảo dưỡng: bắt đầu bằng quét QR + checklist + hoàn thành.
class MaintenanceTaskView extends GetView<MaintenanceTaskController> {
  const MaintenanceTaskView({super.key});

  @override
  String? get tag => Get.parameters['id'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value && controller.item.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('maintenance.title'.tr)),
          body: const LoadingList(),
        );
      }
      final err = controller.error.value;
      if (err != null && controller.item.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('maintenance.title'.tr)),
          body: ErrorState(error: err, onRetry: controller.load),
        );
      }
      final t = controller.item.value!;
      return Scaffold(
        appBar: AppBar(
          title: Text(t.code),
          actions: [
            IconButton(
              tooltip: 'repairs.report.open'.tr,
              icon: const Icon(LucideIcons.fileText),
              onPressed: () => _exportPdf(context, controller),
            ),
            IconButton(
              tooltip: 'common.share'.tr,
              icon: const Icon(LucideIcons.share2),
              onPressed: () => _exportPdf(context, controller, share: true),
            ),
            if (controller.canStart)
              IconButton(
                tooltip: 'maintenance.skip'.tr,
                icon: const Icon(LucideIcons.skipForward),
                onPressed: () => _skip(controller),
              ),
          ],
        ),
        body: Column(
          children: [
            _Header(t: t, controller: controller),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  for (final item in t.templateItems)
                    _ChecklistCard(item: item, controller: controller),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomBar(t: t, controller: controller),
      );
    });
  }

  Future<void> _exportPdf(
    BuildContext context,
    MaintenanceTaskController c, {
    bool share = false,
  }) async {
    try {
      await exportMaintenancePdf(c.id, share: share);
    } catch (e) {
      AppSnackbar.error(e);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.t, required this.controller});

  final MaintenanceTask t;
  final MaintenanceTaskController controller;

  @override
  Widget build(BuildContext context) {
    final overdue = t.status == 'overdue';
    return DetailHeaderCard(
      icon: LucideIcons.calendarCheck,
      title: t.equipmentLabel,
      onTitleTap: () => Get.toNamed(Routes.equipment(t.equipmentId)),
      code: t.code,
      badges: [
        StatusBadge(
          tone: toneForTaskStatus(t.status),
          label: 'status.task.${t.status}'.tr,
        ),
      ],
      stats: [
        DetailStat(
          'maintenance.scheduled'.tr,
          formatDateTime(t.scheduledAt),
          icon: LucideIcons.calendarDays,
        ),
        if (t.dueAt != null)
          DetailStat(
            'maintenance.due'.tr,
            formatDateTime(t.dueAt),
            icon: overdue ? LucideIcons.clockAlert : LucideIcons.clock3,
            color: overdue ? context.status.danger : null,
          ),
      ],
      extra: Obx(() {
        final notes = <Widget>[
          if (controller.draftRestored.value)
            Text(
              'maintenance.draftRestored'.tr,
              style: context.appText.caption.copyWith(
                color: context.status.warning,
              ),
            ),
          if (controller.saving.value)
            Text('maintenance.savingDraft'.tr, style: context.appText.caption),
        ];
        if (notes.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: notes,
        );
      }),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.item, required this.controller});

  final ChecklistItem item;
  final MaintenanceTaskController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueController = controller.valueControllers.putIfAbsent(
      item.key,
      () => TextEditingController(
        text: controller.results[item.key]?.value ?? '',
      ),
    );
    final noteController = controller.noteControllers.putIfAbsent(
      item.key,
      () =>
          TextEditingController(text: controller.results[item.key]?.note ?? ''),
    );
    return Obx(() {
      final r = controller.results[item.key];
      final missing = controller.missingKeys.contains(item.key);
      return Card(
        shape: missing
            ? RoundedRectangleBorder(
                side: BorderSide(color: context.status.danger, width: 2),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.label, style: theme.textTheme.titleSmall),
                  ),
                  if (item.optional)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('common.optional'.tr),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              switch (item.type) {
                'measure' => _measure(context, valueController, r),
                'text' => TextField(
                  controller: valueController,
                  onChanged: (v) => controller.setValue(item.key, v),
                  decoration: const InputDecoration(hintText: '…'),
                ),
                _ => _check(context, r),
              },
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: noteController,
                      onChanged: (v) => controller.setNote(item.key, v),
                      decoration: InputDecoration(
                        labelText: 'repairs.logs.note'.tr,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'repairs.form.addPhoto'.tr,
                    icon: Icon(
                      r?.photoFileId == null
                          ? Icons.add_a_photo_outlined
                          : Icons.check_circle_outline,
                      color: r?.photoFileId == null
                          ? null
                          : context.status.success,
                    ),
                    onPressed: () => controller.attachPhoto(item.key),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _check(BuildContext context, TaskResult? r) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        ChoiceChip(
          label: Text('maintenance.result.pass'.tr),
          selected: r?.pass == true,
          onSelected: (v) => controller.setCheck(item.key, v ? true : null),
        ),
        ChoiceChip(
          label: Text('maintenance.result.fail'.tr),
          selected: r?.pass == false,
          onSelected: (v) => controller.setCheck(item.key, v ? false : null),
        ),
        if (item.optional)
          ChoiceChip(
            label: Text('maintenance.result.na'.tr),
            selected: r?.value == 'na',
            onSelected: (v) => controller.setValue(item.key, v ? 'na' : null),
          ),
      ],
    );
  }

  Widget _measure(
    BuildContext context,
    TextEditingController valueController,
    TaskResult? r,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => controller.setValue(item.key, v),
            decoration: InputDecoration(
              hintText: item.unit ?? '',
              isDense: true,
            ),
          ),
        ),
        if (item.min != null || item.max != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${item.min ?? ''} – ${item.max ?? ''} ${item.unit ?? ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (r?.pass != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(
            r!.pass! ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: r.pass! ? context.status.success : context.status.danger,
          ),
        ],
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.t, required this.controller});

  final MaintenanceTask t;
  final MaintenanceTaskController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.canStart) {
      return StickyActionBar(
        primary: GradientButton(
          label: 'maintenance.start'.tr,
          icon: LucideIcons.play,
          onPressed: () => _start(context, controller),
        ),
      );
    }
    if (controller.canFinish) {
      return StickyActionBar(
        secondary: [
          StickySecondaryButton(
            label: 'maintenance.sign'.tr,
            icon: LucideIcons.penLine,
            onPressed: () => _sign(controller),
          ),
        ],
        primary: GradientButton(
          label: 'maintenance.finish'.tr,
          icon: LucideIcons.check,
          onPressed: () => _finish(controller),
        ),
      );
    }
    if (t.status != 'done') return const SizedBox.shrink();
    final pass = t.overallPass == true;
    return StickyActionBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            pass ? LucideIcons.circleCheck : LucideIcons.circleX,
            size: 20,
            color: pass ? context.status.success : context.status.danger,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${'maintenance.overall'.tr}: ${pass ? 'maintenance.result.pass'.tr : 'maintenance.result.fail'.tr}',
            style: context.appText.bodyStrong,
          ),
        ],
      ),
    );
  }
}

Future<void> _start(BuildContext context, MaintenanceTaskController c) async {
  final qr =
      (await Get.toNamed(Routes.scan, arguments: {'continuous': true}))
          as List<String>?;
  final token = qr?.firstOrNull;
  if (token == null) {
    if (!c.isAdmin) return;
    final skip = await Get.dialog<bool>(
      AlertDialog(
        title: Text('maintenance.start'.tr),
        content: Text('maintenance.skipScanHint'.tr),
        actions: [
          TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('maintenance.skipScan'.tr),
          ),
        ],
      ),
    );
    if (skip == true) await c.start();
    return;
  }
  await c.start(qrToken: token);
}

Future<void> _skip(MaintenanceTaskController c) async {
  final reason = TextEditingController();
  await Get.dialog<void>(
    AlertDialog(
      title: Text('maintenance.skip'.tr),
      content: TextField(
        controller: reason,
        decoration: InputDecoration(labelText: 'repairs.cancel.reason'.tr),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
        FilledButton(
          onPressed: () async {
            if (reason.text.trim().isEmpty) return;
            Get.back();
            await c.skip(reason.text.trim());
          },
          child: Text('common.confirm'.tr),
        ),
      ],
    ),
  );
  reason.dispose();
}

Future<void> _finish(MaintenanceTaskController c) async {
  var pass = true;
  final notes = TextEditingController();
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'maintenance.finish'.tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('maintenance.overallPass'.tr),
                value: pass,
                onChanged: (v) => setState(() => pass = v),
              ),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'maintenance.notes'.tr),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final ok = await c.finish(
                    overallPass: pass,
                    notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                  );
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
  notes.dispose();
}

Future<void> _sign(MaintenanceTaskController c) async {
  final name = TextEditingController();
  final role = await Get.dialog<String>(
    AlertDialog(
      title: Text('maintenance.sign'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: 'repairs.sign.signer'.tr),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: 'technician'),
          child: Text('repairs.sign.technician'.tr),
        ),
        FilledButton(
          onPressed: () => Get.back(result: 'department'),
          child: Text('repairs.sign.department'.tr),
        ),
      ],
    ),
  );
  if (role == null || name.text.trim().isEmpty) {
    name.dispose();
    return;
  }
  await c.sign(role: role, signerName: name.text.trim());
  name.dispose();
}

/// Tải PDF biên bản bảo dưỡng rồi mở ngoài app hoặc chia sẻ.
Future<void> exportMaintenancePdf(String taskId, {bool share = false}) async {
  final bytes = await Get.find<TasksRepository>().reportPdf(taskId);
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/bien-ban-bd-$taskId.pdf');
  await file.writeAsBytes(bytes, flush: true);
  if (share) {
    await PdfFileService.share(file);
  } else {
    await PdfFileService.open(file);
  }
}
