import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
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
          return EmptyState(
            icon: Icons.extension_outlined,
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
              final a = controller.items[i];
              return Card(
                child: ListTile(
                  title: Text([a.code, a.name].whereType<String>().join(' — ')),
                  subtitle: Text(
                    '${'equipment.accessory.type.${a.type}'.tr} · SL ${a.quantity}',
                  ),
                  trailing: StatusBadge(
                    tone: switch (a.condition) {
                      'good' => StatusTone.success,
                      'worn' => StatusTone.warning,
                      _ => StatusTone.danger,
                    },
                    label: 'status.accessory.${a.condition}'.tr,
                  ),
                  onTap: () => _showForm(controller, accessory: a),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addAccessory',
        tooltip: 'equipment.accessory.add'.tr,
        onPressed: () => _showForm(controller),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _showForm(
  AccessoriesTabController c, {
  EquipmentAccessory? accessory,
}) async {
  final name = TextEditingController(text: accessory?.name ?? '');
  final code = TextEditingController(text: accessory?.code ?? '');
  final qty = TextEditingController(
    text: accessory?.quantity.toString() ?? '1',
  );
  final note = TextEditingController(text: accessory?.notes ?? '');
  var type = accessory?.type ?? 'other';
  var condition = accessory?.condition ?? 'good';

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
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  (accessory == null
                          ? 'equipment.accessory.add'
                          : 'equipment.accessory.edit')
                      .tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'equipment.accessory.name'.tr,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: code,
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
                  onChanged: (v) => setState(() => type = v ?? type),
                ),
                const SizedBox(height: AppSpacing.sm),
                QtyField(
                  controller: qty,
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
                  onChanged: (v) => setState(() => condition = v ?? condition),
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
                    final q = qty.text;
                    final ok = await c.save(
                      id2: accessory?.id,
                      name: name.text.trim(),
                      code: code.text.trim(),
                      type: type,
                      quantity: num.tryParse(q.replaceAll(',', '.')) ?? 1,
                      condition: condition,
                      note: note.text.trim(),
                    );
                    if (ok) Get.back();
                  },
                  child: Text('common.save'.tr),
                ),
                if (accessory != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      Get.back();
                      final ok = await ConfirmSheet.show(
                        title: 'attachment.deleteConfirm'.tr,
                        destructive: true,
                      );
                      if (ok) await c.remove(accessory.id);
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
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  name.dispose();
  code.dispose();
  qty.dispose();
  note.dispose();
}
