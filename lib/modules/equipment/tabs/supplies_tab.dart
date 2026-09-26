import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../../core/format/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../data/models/equipment_extras.dart';
import '../../../data/repositories/equipment_repository.dart';
import '../../../data/repositories/supplies_repository.dart';

/// Tab "Vật tư đi theo máy": mapping vật tư + runway `daysLeft`.
class SuppliesTabController extends GetxController {
  SuppliesTabController({
    required this.equipment,
    required this.supplies,
    required this.id,
  });

  final EquipmentRepository equipment;
  final SuppliesRepository supplies;
  final String id;

  final RxList<EquipmentSupplyLink> links = <EquipmentSupplyLink>[].obs;
  final Rxn<EquipmentRunway> runway = Rxn<EquipmentRunway>();
  final RxMap<String, String> supplyLabels = <String, String>{}.obs;
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
      links.assignAll(await equipment.supplies(id));
      await _loadLabels();
      try {
        runway.value = await equipment.runway(id);
      } catch (_) {
        runway.value = null; // runway là best-effort
      }
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _loadLabels() async {
    for (final l in links) {
      if (supplyLabels.containsKey(l.supplyId)) continue;
      try {
        final s = await supplies.byId(l.supplyId);
        supplyLabels[l.supplyId] = '${s.code} — ${s.name}';
      } catch (_) {
        supplyLabels[l.supplyId] = 'equipment.supply.unknown'.tr;
      }
    }
  }

  RunwayItem? runwayOf(String supplyId) {
    final r = runway.value;
    if (r == null) return null;
    for (final item in r.items) {
      if (item.supplyId == supplyId) return item;
    }
    return null;
  }

  Future<void> add(BuildContext context) async {
    final selection = await PickerSheet.show<String>(
      context,
      title: 'equipment.action.issueSupplies'.tr,
      kind: PickerKind.supply,
      loader: (q) async {
        final page = await supplies.list(q: q, limit: 20);
        return [
          for (final s in page.items)
            PickerOption(value: s.id, code: s.code, name: s.name),
        ];
      },
    );
    final supply = selection?.option;
    if (supply == null) return;
    if (links.any((l) => l.supplyId == supply.value)) return;
    links.add(
      EquipmentSupplyLink(supplyId: supply.value, isPrimary: links.isEmpty),
    );
    await _save();
  }

  Future<void> removeAt(int index) async {
    links.removeAt(index);
    await _save();
  }

  Future<void> _save() async {
    try {
      await equipment.putSupplies(id, links.toList());
      AppSnackbar.success('equipment.supply.saved'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }
}

class SuppliesTab extends GetView<SuppliesTabController> {
  const SuppliesTab({super.key});

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
        if (controller.links.isEmpty) {
          return EmptyState(
            icon: LucideIcons.package2,
            title: 'equipment.supply.none'.tr,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: controller.links.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final l = controller.links[i];
            final runway = controller.runwayOf(l.supplyId);
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(
                  controller.supplyLabels[l.supplyId] ??
                      'equipment.supply.unknown'.tr,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (l.normQtyPerDay != null || l.normQtyPerTest != null)
                      Text(
                        [
                          if (l.normQtyPerDay != null)
                            '${'equipment.supply.normPerDay'.tr}: ${formatVnd(l.normQtyPerDay, symbol: false)}',
                          if (l.normQtyPerTest != null)
                            '${'equipment.supply.normPerTest'.tr}: ${formatVnd(l.normQtyPerTest, symbol: false)}',
                        ].join(' · '),
                      ),
                    if (runway != null)
                      Row(
                        children: [
                          Icon(
                            LucideIcons.trendingDown,
                            size: 16,
                            color: _runwayColor(context, runway.daysLeft),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${'equipment.supply.runway'.tr}: ${'equipment.supply.daysLeft'.trParams({'days': runway.daysLeft.toString()})} (${'equipment.supply.basis.${runway.basis}'.tr})',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _runwayColor(context, runway.daysLeft),
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: AppIconButton(
                  tone: AppButtonTone.danger,
                  tooltip: 'common.delete'.tr,
                  icon: LucideIcons.x,
                  onPressed: () => controller.removeAt(i),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addSupply',
        onPressed: () => controller.add(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Color _runwayColor(BuildContext context, num daysLeft) {
    if (daysLeft < 7) return context.status.danger;
    if (daysLeft < 30) return context.status.warning;
    return context.status.success;
  }
}
