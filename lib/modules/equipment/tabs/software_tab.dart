import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/format/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/timeline_list.dart';
import '../../../data/models/equipment_parts.dart';
import '../../../data/repositories/equipment_repository.dart';

/// Tab "Phần mềm": CRUD, xem key (10 giây), nâng cấp, lịch sử.
class SoftwareTabController extends GetxController {
  SoftwareTabController({required this.equipment, required this.id});

  final EquipmentRepository equipment;
  final String id;

  final RxList<EquipmentSoftware> items = <EquipmentSoftware>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  /// Key đang hiện theo phần mềm (tự ẩn sau 10 giây).
  final RxMap<String, String> shownKeys = <String, String>{}.obs;
  final Map<String, Timer> _timers = {};

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      items.assignAll(await equipment.software(id));
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> revealKey(EquipmentSoftware s) async {
    try {
      final key = await equipment.licenseKey(id, s.id);
      shownKeys[s.id] = key;
      _timers[s.id]?.cancel();
      _timers[s.id] = Timer(const Duration(seconds: 10), () {
        shownKeys.remove(s.id);
      });
      await Clipboard.setData(ClipboardData(text: key));
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<bool> save({
    String? sid,
    required String name,
    String? version,
    String? licenseUntil,
    String? note,
  }) async {
    final payload = {
      'name': name,
      'version': ?version,
      'licenseExpiresAt': ?licenseUntil,
      'notes': ?note,
    };
    try {
      if (sid == null) {
        await equipment.createSoftware(id, payload);
      } else {
        await equipment.updateSoftware(id, sid, payload);
      }
      AppSnackbar.success('equipment.software.saved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<void> remove(String sid) async {
    try {
      await equipment.deleteSoftware(id, sid);
      AppSnackbar.success('equipment.software.deleted'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<bool> upgrade(
    EquipmentSoftware s,
    String toVersion,
    String? note,
  ) async {
    try {
      await equipment.upgradeSoftware(
        id,
        s.id,
        toVersion: toVersion,
        note: note,
      );
      AppSnackbar.success('equipment.software.upgraded'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<List<SoftwareHistoryItem>> history(String sid) =>
      equipment.softwareHistory(id, sid);

  @override
  void onClose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.onClose();
  }
}

class SoftwareTab extends GetView<SoftwareTabController> {
  const SoftwareTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.loading.value) return const LoadingList();
        if (controller.error.value != null) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.items.isEmpty) {
          return EmptyState(
            icon: LucideIcons.terminal,
            title: 'common.empty'.tr,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final s = controller.items[i];
              final expired =
                  s.licenseExpiresAt != null &&
                  (DateTime.tryParse(
                        s.licenseExpiresAt!,
                      )?.isBefore(DateTime.now()) ??
                      false);
              return AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      '${'equipment.software.version'.tr}: ${s.version ?? '—'}',
                    ),
                    Text(
                      '${'equipment.software.license'.tr}: ${formatDate(s.licenseExpiresAt)}',
                      style: TextStyle(
                        color: expired
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                    Obx(() {
                      final shown = controller.shownKeys[s.id];
                      if (shown == null) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: AppButton.soft(
                            tone: AppButtonTone.primary,
                            icon: LucideIcons.keyRound,
                            label: s.hasLicenseKey
                                ? 'equipment.software.viewKey'.tr
                                : 'equipment.software.noKey'.tr,
                            onPressed: s.hasLicenseKey
                                ? () => controller.revealKey(s)
                                : null,
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            shown,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'equipment.software.keyHidden'.tr,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppButton.soft(
                          tone: AppButtonTone.primary,
                          label: 'equipment.software.upgrade'.tr,
                          onPressed: () =>
                              _upgradeDialog(context, controller, s),
                        ),
                        AppButton.soft(
                          tone: AppButtonTone.primary,
                          label: 'equipment.software.history'.tr,
                          onPressed: () =>
                              _historySheet(context, controller, s),
                        ),
                        AppButton.soft(
                          tone: AppButtonTone.primary,
                          label: 'common.edit'.tr,
                          onPressed: () =>
                              _formSheet(context, controller, software: s),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addSoftware',
        onPressed: () => _formSheet(context, controller),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

Future<void> _formSheet(
  BuildContext context,
  SoftwareTabController c, {
  EquipmentSoftware? software,
}) async {
  var deleteRequested = false;
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      initial: {
        'name': software?.name,
        'version': software?.version,
        'license': software?.licenseExpiresAt == null
            ? ''
            : formatDate(software!.licenseExpiresAt),
        'note': software?.notes,
      },
      builder: (context, form) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title:
                  (software == null ? 'equipment.software.add' : 'common.edit')
                      .tr,
            ),
            TextField(
              controller: form.field('name'),
              focusNode: form.focusNode('name'),
              decoration: InputDecoration(
                labelText: 'equipment.software.name'.tr,
                errorText: form.error('name'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('version'),
              decoration: InputDecoration(
                labelText: 'equipment.software.version'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('license'),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.tryParse(software?.licenseExpiresAt ?? '') ??
                      DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  form.field('license').text = formatDate(picked);
                }
              },
              decoration: InputDecoration(
                labelText: 'equipment.software.license'.tr,
                suffixIcon: const Icon(LucideIcons.calendarDays),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('note'),
              decoration: InputDecoration(
                labelText: 'equipment.accessory.note'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: 'common.save'.tr,
              onPressed: form.busy
                  ? null
                  : () async {
                      if (form.text('name').isEmpty) {
                        form.setError('name', 'common.required'.tr);
                        return;
                      }
                      form.setBusy(true);
                      final ok = await c.save(
                        sid: software?.id,
                        name: form.text('name'),
                        version: form.text('version'),
                        licenseUntil: _iso(form.text('license')),
                        note: form.text('note'),
                      );
                      form.setBusy(false);
                      if (ok) form.close();
                    },
            ),
            if (software != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton.soft(
                tone: AppButtonTone.danger,
                icon: LucideIcons.trash2,
                label: 'common.delete'.tr,
                onPressed: () {
                  deleteRequested = true;
                  form.close();
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
  if (deleteRequested && software != null && context.mounted) {
    final ok = await ConfirmSheet.show(
      context,
      title: 'attachment.deleteConfirm'.tr,
      destructive: true,
    );
    if (ok) await c.remove(software.id);
  }
}

String? _iso(String? display) {
  if (display == null || display.isEmpty) return null;
  final parts = display.split('/');
  if (parts.length != 3) return null;
  return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
}

Future<void> _upgradeDialog(
  BuildContext context,
  SoftwareTabController c,
  EquipmentSoftware s,
) async {
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'equipment.software.upgrade'.tr),
          TextField(
            controller: form.field('version'),
            focusNode: form.focusNode('version'),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'equipment.software.upgradeTo'.tr,
              errorText: form.error('version'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: form.field('note'),
            decoration: InputDecoration(
              labelText: 'equipment.accessory.note'.tr,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: 'common.save'.tr,
            onPressed: form.busy
                ? null
                : () async {
                    if (form.text('version').isEmpty) {
                      form.setError('version', 'common.required'.tr);
                      return;
                    }
                    form.setBusy(true);
                    final ok = await c.upgrade(
                      s,
                      form.text('version'),
                      form.text('note'),
                    );
                    form.setBusy(false);
                    if (ok) form.close();
                  },
          ),
        ],
      ),
    ),
  );
}

Future<void> _historySheet(
  BuildContext context,
  SoftwareTabController c,
  EquipmentSoftware s,
) async {
  final history = await c.history(s.id);
  if (!context.mounted) return;
  await AppSheet.show<void>(
    context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'equipment.software.history'.tr,
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TimelineList(
            items: [
              for (final h in history)
                TimelineEntry(
                  title: '${h.fromVersion ?? '—'} → ${h.toVersion}',
                  at: h.changedAt,
                  summary: h.note,
                  by: h.changedBy,
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
