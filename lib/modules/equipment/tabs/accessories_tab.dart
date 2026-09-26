import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/list_item_card.dart';
import '../../../core/widgets/qty_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/equipment_parts.dart';
import '../../../data/repositories/equipment_repository.dart';

const kAccessoryTypes = [
  'power_cable',
  'data_cable',
  'tube',
  'probe',
  'ups',
  'other',
];
const kAccessoryConditions = ['good', 'worn', 'broken'];

/// Tab "Phụ kiện": CRUD danh sách phụ kiện máy.
class AccessoriesTabController extends GetxController {
  AccessoriesTabController({required this.equipment, required this.id});

  final EquipmentRepository equipment;
  final String id;

  final RxList<EquipmentAccessory> items = <EquipmentAccessory>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      items.assignAll(await equipment.accessories(id));
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> save({
    String? id2,
    required String name,
    String? code,
    required String type,
    required num quantity,
    required String condition,
    String? note,
  }) async {
    final payload = {
      'name': name,
      'code': ?code,
      'type': type,
      'quantity': quantity,
      'condition': condition,
      'notes': ?note,
    };
    try {
      if (id2 == null) {
        await equipment.createAccessory(id, payload);
      } else {
        await equipment.updateAccessory(id, id2, payload);
      }
      AppSnackbar.success('equipment.accessory.saved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<void> remove(String aid) async {
    try {
      await equipment.deleteAccessory(id, aid);
      AppSnackbar.success('equipment.accessory.deleted'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }
}

class AccessoriesTab extends GetView<AccessoriesTabController> {
  const AccessoriesTab({super.key});

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
          return EmptyState(icon: LucideIcons.puzzle, title: 'common.empty'.tr);
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final a = controller.items[i];
              return ListItemCard(
                title: [a.code, a.name].whereType<String>().join(' — '),
                badge: StatusBadge(
                  tone: switch (a.condition) {
                    'good' => StatusTone.success,
                    'worn' => StatusTone.warning,
                    _ => StatusTone.danger,
                  },
                  label: 'status.accessory.${a.condition}'.tr,
                ),
                metas: [
                  ListMeta(
                    LucideIcons.puzzle,
                    '${'equipment.accessory.type.${a.type}'.tr} · SL ${a.quantity}',
                  ),
                ],
                onTap: () => _showForm(context, controller, accessory: a),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addAccessory',
        tooltip: 'equipment.accessory.add'.tr,
        onPressed: () => _showForm(context, controller),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

Future<void> _showForm(
  BuildContext context,
  AccessoriesTabController c, {
  EquipmentAccessory? accessory,
}) async {
  var type = accessory?.type ?? 'other';
  var condition = accessory?.condition ?? 'good';
  var deleteRequested = false;

  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      initial: {
        'name': accessory?.name,
        'code': accessory?.code,
        'qty': accessory?.quantity.toString() ?? '1',
        'note': accessory?.notes,
      },
      builder: (context, form) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title:
                  (accessory == null
                          ? 'equipment.accessory.add'
                          : 'equipment.accessory.edit')
                      .tr,
            ),
            TextField(
              controller: form.field('name'),
              focusNode: form.focusNode('name'),
              decoration: InputDecoration(
                labelText: 'equipment.accessory.name'.tr,
                errorText: form.error('name'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('code'),
              decoration: InputDecoration(
                labelText: 'equipment.accessory.code'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: InputDecoration(
                labelText: 'equipment.accessory.type'.tr,
              ),
              items: [
                for (final t in kAccessoryTypes)
                  DropdownMenuItem(
                    value: t,
                    child: Text('equipment.accessory.type.$t'.tr),
                  ),
              ],
              onChanged: (v) => form.refresh(() => type = v ?? type),
            ),
            const SizedBox(height: AppSpacing.sm),
            QtyField(
              controller: form.field('qty'),
              label: 'equipment.accessory.quantity'.tr,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: condition,
              decoration: InputDecoration(
                labelText: 'equipment.accessory.condition'.tr,
              ),
              items: [
                for (final t in kAccessoryConditions)
                  DropdownMenuItem(
                    value: t,
                    child: Text('status.accessory.$t'.tr),
                  ),
              ],
              onChanged: (v) => form.refresh(() => condition = v ?? condition),
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
                        id2: accessory?.id,
                        name: form.text('name'),
                        code: form.text('code'),
                        type: type,
                        quantity:
                            num.tryParse(
                              form.text('qty').replaceAll(',', '.'),
                            ) ??
                            1,
                        condition: condition,
                        note: form.text('note'),
                      );
                      form.setBusy(false);
                      if (ok) form.close();
                    },
            ),
            if (accessory != null) ...[
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
  if (deleteRequested && accessory != null && context.mounted) {
    final ok = await ConfirmSheet.show(
      context,
      title: 'attachment.deleteConfirm'.tr,
      destructive: true,
    );
    if (ok) await c.remove(accessory.id);
  }
}
