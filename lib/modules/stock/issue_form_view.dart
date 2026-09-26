import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/qty_field.dart';
import '../../data/models/department.dart';
import '../../data/models/stock.dart';
import '../../data/models/stock_issue.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/stock_repository.dart';
import 'issue_form_controller.dart';

/// Tạo phiếu xuất kho `/stock/issues/new`.
class IssueFormView extends GetView<IssueFormController> {
  const IssueFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('stock.issue.new'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Obx(
            () => Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final t in IssueFormController.types)
                  ChoiceChip(
                    label: Text('stock.issue.type.$t'.tr),
                    selected: controller.type.value == t,
                    onSelected: (v) {
                      if (v) controller.type.value = t;
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.warehouse),
              title: Text(
                controller.warehouse.value == null
                    ? 'stock.receipt.warehouse'.tr
                    : controller.warehouse.value!.name,
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => controller.pickWarehouse(context),
            ),
          ),
          if (controller.type.value == 'to_department')
            Obx(
              () => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.building2),
                title: Text(
                  controller.toDepartment.value == null
                      ? 'stock.issue.toDepartment'.tr
                      : controller.toDepartment.value!.name,
                ),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => controller.pickToDepartment(context),
              ),
            ),
          Obx(
            () => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.flaskConical),
              title: Text(
                controller.equipment.value == null
                    ? 'stock.issue.equipment'.tr
                    : controller.equipment.value!.name,
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => _pickEquipment(context, controller),
            ),
          ),
          TextField(
            controller: controller.receiverName,
            decoration: InputDecoration(labelText: 'stock.issue.receiver'.tr),
          ),
          if (controller.reasonRequired)
            TextField(
              controller: controller.reason,
              decoration: InputDecoration(labelText: 'stock.issue.reason'.tr),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scanLot(context, controller),
                  icon: const Icon(LucideIcons.scanQrCode),
                  label: Text('stock.issue.scanLot'.tr),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickSupply(context, controller),
                  icon: const Icon(LucideIcons.list),
                  label: Text('stock.receipt.pickSupply'.tr),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => Column(
              children: [
                for (var i = 0; i < controller.lines.length; i++)
                  Card(
                    child: ListTile(
                      title: Text(controller.lines[i].label),
                      subtitle: Text(
                        'SL ${controller.lines[i].quantity}'
                        '${controller.lines[i].lotNo == null ? '' : ' · Lô ${controller.lines[i].lotNo}'}'
                        '${controller.lines[i].fefoWarning ? ' · ⚠ ${'stock.issue.fefoWarn'.tr}' : ''}',
                        style: controller.lines[i].fefoWarning
                            ? TextStyle(color: theme.colorScheme.tertiary)
                            : null,
                      ),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => controller.removeLine(i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Obx(
            () => controller.error.value.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    controller.error.value,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => FilledButton.icon(
              onPressed: controller.submitting.value ? null : controller.save,
              icon: const Icon(LucideIcons.save),
              label: Text('stock.issue.saveDraft'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickEquipment(
    BuildContext context,
    IssueFormController c,
  ) async {
    final repo = Get.find<EquipmentRepository>();
    final selection = await PickerSheet.show<String>(
      context,
      title: 'stock.issue.equipment'.tr,
      kind: PickerKind.equipment,
      loader: (q) async {
        final page = await repo.search(q, limit: 20);
        return [
          for (final e in page.items)
            PickerOption(value: e.id, code: e.code, name: e.name),
        ];
      },
    );
    final o = selection?.option;
    if (o == null) return;
    c.equipment.value = DepartmentRef(id: o.value, code: o.code, name: o.name);
  }

  Future<void> _scanLot(BuildContext context, IssueFormController c) async {
    final codes =
        (await Get.toNamed(Routes.scan, arguments: {'continuous': true}))
            as List<String>?;
    final code = codes?.firstOrNull;
    if (code == null) return;
    final stockRepo = Get.find<StockRepository>();
    StockLotSummary? lot;
    try {
      final page = await stockRepo.lots(q: code, limit: 5);
      for (final l in page.items) {
        if (l.lotNo.toUpperCase() == code.toUpperCase()) {
          lot = l;
          break;
        }
      }
      lot ??= page.items.length == 1 ? page.items.first : null;
    } catch (_) {
      lot = null;
    }
    if (lot == null) {
      AppSnackbar.error(ApiError(404, 'LOT_NOT_FOUND', ''));
      return;
    }
    if (!context.mounted) return;
    await _lotSheet(context, c, lot);
  }

  Future<void> _lotSheet(
    BuildContext context,
    IssueFormController c,
    StockLotSummary lot,
  ) async {
    await AppSheet.show<void>(
      context,
      builder: (ctx) => SheetForm(
        initial: const {'qty': '1'},
        builder: (context, form) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title:
                  '${'scan.lot.lotNo'.tr}: ${lot.lotNo}'
                  '${lot.expiresAt == null ? '' : ' · ${formatDate(lot.expiresAt)}'}',
            ),
            QtyField(
              controller: form.field('qty'),
              label: 'repairs.parts.quantity'.tr,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: form.busy
                  ? null
                  : () async {
                      form.setBusy(true);
                      final line = IssueLine(
                        supplyId: lot.supplyId,
                        label: lot.lotNo,
                        lotId: lot.id,
                        lotNo: lot.lotNo,
                        quantity: form.text('qty').isEmpty
                            ? '1'
                            : form.text('qty'),
                        available: lot.available,
                      );
                      await c.attachLot(line, lot.id, lot.lotNo);
                      c.lines.add(line);
                      form.close();
                    },
              child: Text('common.add'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSupply(BuildContext context, IssueFormController c) async {
    final selection = await PickerSheet.show<String>(
      context,
      title: 'stock.receipt.pickSupply'.tr,
      kind: PickerKind.supply,
      loader: (q) async {
        final page = await c.supplies.list(q: q, limit: 20);
        return [
          for (final s in page.items)
            PickerOption(value: s.id, code: s.code, name: s.name),
        ];
      },
    );
    final o = selection?.option;
    if (o == null || !context.mounted) return;
    final qty = await AppDialog.prompt(
      context,
      title: '${o.code} — ${o.name}',
      label: 'repairs.parts.quantity'.tr,
      initial: '1',
      confirmLabel: 'common.add'.tr,
    );
    if (qty == null) return;
    await c.addSupplyLine(
      SupplySummary(id: o.value, code: o.code, name: o.name),
      qty.isEmpty ? '1' : qty,
    );
  }
}
