import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../../core/format/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/list_item_card.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../core/widgets/qty_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/equipment_parts.dart';
import '../../../data/models/repair_detail.dart';
import '../../../data/repositories/equipment_repository.dart';
import '../../../data/repositories/repairs_repository.dart';
import '../../../data/repositories/supplies_repository.dart';

/// Tab "Linh kiện/vật tư" của phiếu sửa chữa.
class PartsTabController extends GetxController {
  PartsTabController({
    required this.repairs,
    required this.supplies,
    required this.equipment,
    required this.ticketId,
    required this.equipmentId,
  });

  final RepairsRepository repairs;
  final SuppliesRepository supplies;
  final EquipmentRepository equipment;
  final String ticketId;

  /// Gán từ view khi đã có hồ sơ máy (form linh kiện cần).
  String equipmentId;

  final RxList<RepairPart> items = <RepairPart>[].obs;
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
      items.assignAll(await repairs.parts(ticketId));
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<List<EquipmentComponent>> components() =>
      equipment.components(equipmentId);

  Future<bool> addStock({
    required String supplyId,
    required String name,
    required String quantity,
    String? note,
  }) => _add({
    'source': 'stock',
    'supplyId': supplyId,
    'name': name,
    'quantity': quantity,
    'note': ?note,
  });

  Future<bool> addPurchased({
    required String name,
    required String quantity,
    String? unitCost,
    String? note,
  }) => _add({
    'source': 'purchased',
    'name': name,
    'quantity': quantity,
    'unitCost': ?unitCost,
    'note': ?note,
  });

  Future<bool> addComponentReplace({
    required String componentId,
    required String name,
    String? newSerial,
    String? cost,
    String? reason,
  }) => _add({
    'source': 'component_replace',
    'componentId': componentId,
    'name': name,
    'quantity': '1',
    'newSerial': ?newSerial,
    'cost': ?cost,
    'reason': ?reason,
  });

  Future<bool> _add(Map<String, dynamic> data) async {
    try {
      await repairs.addPart(ticketId, data);
      AppSnackbar.success('repairs.parts.saved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }
}

class PartsTab extends GetView<PartsTabController> {
  const PartsTab({super.key, required this.equipmentId});

  final String equipmentId;

  @override
  String? get tag => Get.parameters['id'];

  @override
  Widget build(BuildContext context) {
    controller.equipmentId = equipmentId;
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
            icon: LucideIcons.package2,
            title: 'repairs.parts.empty'.tr,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final p = controller.items[i];
              return ListItemCard(
                title: p.name,
                badge: StatusBadge(
                  tone: switch (p.source) {
                    'stock' => StatusTone.info,
                    'purchased' => StatusTone.warning,
                    _ => StatusTone.muted,
                  },
                  label: 'repairs.parts.source.${p.source}'.tr,
                ),
                metas: [
                  ListMeta(
                    LucideIcons.hash,
                    '${'repairs.parts.quantity'.tr}: ${p.quantity}'
                    '${p.unitCost == null ? '' : ' · ${formatVnd(p.unitCost)}'}',
                  ),
                ],
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addPart',
        tooltip: 'repairs.parts.add'.tr,
        onPressed: () => _addPart(context, controller),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

Future<void> _addPart(BuildContext context, PartsTabController c) async {
  var source = 'stock';
  await AppSheet.show<void>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: 'repairs.parts.add'.tr),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final s in ['stock', 'purchased', 'component_replace'])
                  ChoiceChip(
                    label: Text('repairs.parts.source.$s'.tr),
                    selected: source == s,
                    onSelected: (v) {
                      if (v) setState(() => source = s);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (source == 'stock')
              _StockForm(c: c)
            else if (source == 'purchased')
              _PurchasedForm(c: c)
            else
              _ComponentForm(c: c),
          ],
        ),
      ),
    ),
  );
}

class _StockForm extends StatefulWidget {
  const _StockForm({required this.c});

  final PartsTabController c;

  @override
  State<_StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<_StockForm> {
  final qty = TextEditingController(text: '1');
  final note = TextEditingController();
  ({String id, String label})? supply;

  @override
  void dispose() {
    qty.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(supply?.label ?? 'repairs.parts.pickSupply'.tr),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () async {
            final selection = await PickerSheet.show<String>(
              context,
              title: 'repairs.parts.pickSupply'.tr,
              kind: PickerKind.supply,
              loader: (q) async {
                final page = await widget.c.supplies.list(q: q, limit: 20);
                return [
                  for (final s in page.items)
                    PickerOption(value: s.id, code: s.code, name: s.name),
                ];
              },
            );
            final o = selection?.option;
            if (o != null) {
              setState(() => supply = (id: o.value, label: o.label));
            }
          },
        ),
        QtyField(controller: qty, label: 'repairs.parts.quantity'.tr),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: note,
          decoration: InputDecoration(labelText: 'repairs.logs.note'.tr),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () async {
            if (supply == null || qty.text.trim().isEmpty) return;
            final ok = await widget.c.addStock(
              supplyId: supply!.id,
              name: supply!.label,
              quantity: qty.text.trim(),
              note: note.text.trim().isEmpty ? null : note.text.trim(),
            );
            if (ok && context.mounted) AppSheet.close(context);
          },
          child: Text('common.save'.tr),
        ),
      ],
    );
  }
}

class _PurchasedForm extends StatefulWidget {
  const _PurchasedForm({required this.c});

  final PartsTabController c;

  @override
  State<_PurchasedForm> createState() => _PurchasedFormState();
}

class _PurchasedFormState extends State<_PurchasedForm> {
  final name = TextEditingController();
  final qty = TextEditingController(text: '1');
  final cost = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    qty.dispose();
    cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: name,
          decoration: InputDecoration(labelText: 'repairs.parts.name'.tr),
        ),
        const SizedBox(height: AppSpacing.sm),
        QtyField(controller: qty, label: 'repairs.parts.quantity'.tr),
        const SizedBox(height: AppSpacing.sm),
        MoneyField(controller: cost, label: 'repairs.parts.unitCost'.tr),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            final ok = await widget.c.addPurchased(
              name: name.text.trim(),
              quantity: qty.text.trim(),
              unitCost: MoneyField.raw(cost.text).isEmpty
                  ? null
                  : MoneyField.raw(cost.text),
            );
            if (ok && context.mounted) AppSheet.close(context);
          },
          child: Text('common.save'.tr),
        ),
      ],
    );
  }
}

class _ComponentForm extends StatefulWidget {
  const _ComponentForm({required this.c});

  final PartsTabController c;

  @override
  State<_ComponentForm> createState() => _ComponentFormState();
}

class _ComponentFormState extends State<_ComponentForm> {
  final serial = TextEditingController();
  final cost = TextEditingController();
  final reason = TextEditingController();
  EquipmentComponent? component;
  List<EquipmentComponent> options = const [];

  @override
  void initState() {
    super.initState();
    widget.c.components().then((v) => setState(() => options = v));
  }

  @override
  void dispose() {
    serial.dispose();
    cost.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: component?.id,
          decoration: InputDecoration(labelText: 'repairs.parts.component'.tr),
          items: [
            for (final c in options)
              DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => setState(
            () => component = options.where((c) => c.id == v).firstOrNull,
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
        MoneyField(controller: cost, label: 'equipment.component.cost'.tr),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: reason,
          decoration: InputDecoration(
            labelText: 'equipment.component.reason'.tr,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () async {
            if (component == null) return;
            final ok = await widget.c.addComponentReplace(
              componentId: component!.id,
              name: component!.name,
              newSerial: serial.text.trim().isEmpty ? null : serial.text.trim(),
              cost: MoneyField.raw(cost.text).isEmpty
                  ? null
                  : MoneyField.raw(cost.text),
              reason: reason.text.trim().isEmpty ? null : reason.text.trim(),
            );
            if (ok && context.mounted) AppSheet.close(context);
          },
          child: Text('common.save'.tr),
        ),
      ],
    );
  }
}
