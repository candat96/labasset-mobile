import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/format/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
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
            icon: Icons.terminal_outlined,
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
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
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
                            child: TextButton.icon(
                              onPressed: s.hasLicenseKey
                                  ? () => controller.revealKey(s)
                                  : null,
                              icon: const Icon(Icons.key_outlined, size: 18),
                              label: Text(
                                s.hasLicenseKey
                                    ? 'equipment.software.viewKey'.tr
                                    : 'equipment.software.noKey'.tr,
                              ),
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
                        children: [
                          OutlinedButton(
                            onPressed: () => _upgradeDialog(controller, s),
                            child: Text('equipment.software.upgrade'.tr),
                          ),
                          OutlinedButton(
                            onPressed: () => _historySheet(controller, s),
                            child: Text('equipment.software.history'.tr),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                _formSheet(controller, software: s),
                            child: Text('common.edit'.tr),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addSoftware',
        onPressed: () => _formSheet(controller),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _formSheet(
  SoftwareTabController c, {
  EquipmentSoftware? software,
}) async {
  final name = TextEditingController(text: software?.name ?? '');
  final version = TextEditingController(text: software?.version ?? '');
  final license = TextEditingController(
    text: software?.licenseExpiresAt == null
        ? ''
        : formatDate(software!.licenseExpiresAt),
  );
  final note = TextEditingController(text: software?.notes ?? '');

  await Get.bottomSheet(
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
                (software == null ? 'equipment.software.add' : 'common.edit')
                    .tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: 'equipment.software.name'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: version,
                decoration: InputDecoration(
                  labelText: 'equipment.software.version'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: license,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: Get.context!,
                    initialDate:
                        DateTime.tryParse(software?.licenseExpiresAt ?? '') ??
                        DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) license.text = formatDate(picked);
                },
                decoration: InputDecoration(
                  labelText: 'equipment.software.license'.tr,
                  suffixIcon: const Icon(Icons.event_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: 'equipment.accessory.note'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final iso = _iso(license.text);
                  final ok = await c.save(
                    sid: software?.id,
                    name: name.text.trim(),
                    version: version.text.trim(),
                    licenseUntil: iso,
                    note: note.text.trim(),
                  );
                  if (ok) Get.back();
                },
                child: Text('common.save'.tr),
              ),
              if (software != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Get.theme.colorScheme.error,
                  ),
                  onPressed: () async {
                    Get.back();
                    final ok = await ConfirmSheet.show(
                      title: 'attachment.deleteConfirm'.tr,
                      destructive: true,
                    );
                    if (ok) await c.remove(software.id);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text('common.delete'.tr),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  name.dispose();
  version.dispose();
  license.dispose();
  note.dispose();
}

String? _iso(String? display) {
  if (display == null || display.isEmpty) return null;
  final parts = display.split('/');
  if (parts.length != 3) return null;
  return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
}

Future<void> _upgradeDialog(
  SoftwareTabController c,
  EquipmentSoftware s,
) async {
  final version = TextEditingController();
  final note = TextEditingController();
  await Get.dialog<void>(
    AlertDialog(
      title: Text('equipment.software.upgrade'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: version,
            decoration: InputDecoration(
              labelText: 'equipment.software.upgradeTo'.tr,
            ),
          ),
          TextField(
            controller: note,
            decoration: InputDecoration(
              labelText: 'equipment.accessory.note'.tr,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
        FilledButton(
          onPressed: () async {
            if (version.text.trim().isEmpty) return;
            final ok = await c.upgrade(
              s,
              version.text.trim(),
              note.text.trim(),
            );
            if (ok) Get.back();
          },
          child: Text('common.save'.tr),
        ),
      ],
    ),
  );
  version.dispose();
  note.dispose();
}

Future<void> _historySheet(SoftwareTabController c, EquipmentSoftware s) async {
  final history = await c.history(s.id);
  await Get.bottomSheet(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'equipment.software.history'.tr,
              style: Get.textTheme.titleMedium,
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
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
}
