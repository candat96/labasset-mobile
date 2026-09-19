import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/equipment_parts.dart';
import '../../../data/repositories/equipment_repository.dart';

/// Tab "Linh kiện": danh sách + progress `usedPct` + thay thế.
class ComponentsTabController extends GetxController {
  ComponentsTabController({required this.equipment, required this.id});

  final EquipmentRepository equipment;
  final String id;

  final RxList<EquipmentComponent> items = <EquipmentComponent>[].obs;
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
      items.assignAll(await equipment.components(id));
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> replace(
    EquipmentComponent c, {
    required String reason,
    String? newSerial,
    String? cost,
  }) async {
    try {
      await equipment.replaceComponent(
        id,
        c.id,
        reason: reason,
        newSerial: newSerial,
        cost: cost,
      );
      AppSnackbar.success('equipment.component.replaced'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }
}

class ComponentsTab extends GetView<ComponentsTabController> {
  const ComponentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) return const LoadingList();
      if (controller.error.value != null) {
        return ErrorState(
          error: controller.error.value!,
          onRetry: controller.load,
        );
      }
      if (controller.items.isEmpty) {
        return EmptyState(
          icon: Icons.memory_outlined,
          title: 'equipment.component.none'.tr,
        );
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _ComponentCard(
            component: controller.items[i],
            onReplace: () => _replaceSheet(controller, controller.items[i]),
          ),
        ),
      );
    });
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.component, required this.onReplace});

  final EquipmentComponent component;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = component.usedPct();
    final tone = switch (component.status) {
      'due' => StatusTone.danger,
      'warning' => StatusTone.warning,
      _ => StatusTone.success,
    };
    final color = switch (tone) {
      StatusTone.danger => context.status.danger,
      StatusTone.warning => context.status.warning,
      _ => context.status.success,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      component.partNo,
                      component.name,
                    ].whereType<String>().join(' — '),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                StatusBadge(
                  tone: tone,
                  label: 'status.component.${component.status}'.tr,
                ),
              ],
            ),
            if (component.serial != null)
              Text('${'equipment.serial'.tr}: ${component.serial}'),
            Text(
              '${'equipment.component.installed'.tr}: ${component.installedAt ?? '—'}',
            ),
            if (pct != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pct.clamp(0, 1),
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${(pct * 100).round()}%',
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ],
            if (component.lifespanHours != null ||
                component.lifespanTests != null ||
                component.lifespanMonths != null)
              Text(
                '${'equipment.component.lifespan'.tr}: '
                '${[if (component.lifespanHours != null) '${component.lifespanHours} h', if (component.lifespanTests != null) '${component.lifespanTests} test', if (component.lifespanMonths != null) '${component.lifespanMonths} th'].join(' · ')}',
                style: theme.textTheme.bodySmall,
              ),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onReplace,
                child: Text('equipment.component.replace'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _replaceSheet(
  ComponentsTabController c,
  EquipmentComponent component,
) async {
  final reason = TextEditingController();
  final serial = TextEditingController();
  final cost = TextEditingController();
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
                'equipment.component.replace'.tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(component.name),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: reason,
                decoration: InputDecoration(
                  labelText: 'equipment.component.reason'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: serial,
                decoration: InputDecoration(
                  labelText: 'equipment.component.newSerial'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              MoneyField(
                controller: cost,
                label: 'equipment.component.cost'.tr,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  if (reason.text.trim().isEmpty) return;
                  final ok = await c.replace(
                    component,
                    reason: reason.text.trim(),
                    newSerial: serial.text.trim().isEmpty
                        ? null
                        : serial.text.trim(),
                    cost: MoneyField.raw(cost.text).isEmpty
                        ? null
                        : MoneyField.raw(cost.text),
                  );
                  if (ok) Get.back();
                },
                child: Text('common.save'.tr),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  reason.dispose();
  serial.dispose();
  cost.dispose();
}
