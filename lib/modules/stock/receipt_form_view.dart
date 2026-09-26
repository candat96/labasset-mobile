import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/money_field.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../core/widgets/qty_field.dart';
import '../../data/models/supply.dart';
import 'receipt_form_controller.dart';

/// Tạo phiếu nhập kho — stepper 3 bước.
class ReceiptFormView extends GetView<ReceiptFormController> {
  const ReceiptFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('stock.receipt.new'.tr)),
      body: Column(
        children: [
          Obx(
            () => Stepper(
              currentStep: controller.step.value,
              onStepTapped: (i) {
                if (i <= controller.step.value) controller.step.value = i;
              },
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              steps: [
                Step(
                  title: Text('stock.receipt.step1'.tr),
                  isActive: controller.step.value >= 0,
                  content: _Step1(controller: controller),
                ),
                Step(
                  title: Text('stock.receipt.step2'.tr),
                  isActive: controller.step.value >= 1,
                  content: _Step2(controller: controller),
                ),
                Step(
                  title: Text('stock.receipt.step3'.tr),
                  isActive: controller.step.value >= 2,
                  content: _Step3(controller: controller),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Obx(
            () => Row(
              children: [
                if (controller.step.value > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.back,
                      child: Text('common.back'.tr),
                    ),
                  ),
                if (controller.step.value > 0)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: controller.step.value < 2
                      ? FilledButton(
                          onPressed: controller.canNext
                              ? controller.next
                              : null,
                          child: Text('common.next'.tr),
                        )
                      : FilledButton.icon(
                          onPressed: controller.submitting.value
                              ? null
                              : controller.saveDraft,
                          icon: const Icon(LucideIcons.save),
                          label: Text('stock.receipt.saveDraft'.tr),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  const _Step1({required this.controller});

  final ReceiptFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final t in ReceiptFormController.types)
                ChoiceChip(
                  label: Text('stock.receipt.type.$t'.tr),
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
            title: Text(
              controller.warehouse.value == null
                  ? 'stock.receipt.warehouse'.tr
                  : controller.warehouse.value!.name,
            ),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => controller.pickWarehouse(context),
          ),
        ),
        if (controller.type.value == 'purchase')
          Obx(
            () => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                controller.supplier.value == null
                    ? 'stock.receipt.supplier'.tr
                    : controller.supplier.value!.name,
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => controller.pickSupplier(context),
            ),
          ),
        if (controller.type.value == 'return_from_dept')
          Obx(
            () => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                controller.fromDepartment.value == null
                    ? 'stock.receipt.fromDepartment'.tr
                    : controller.fromDepartment.value!.name,
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => controller.pickFromDepartment(context),
            ),
          ),
        TextField(
          controller: controller.invoiceNo,
          decoration: InputDecoration(labelText: 'stock.receipt.invoiceNo'.tr),
        ),
      ],
    );
  }
}

class _Step2 extends StatelessWidget {
  const _Step2({required this.controller});

  final ReceiptFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _scan(context, controller),
                icon: const Icon(LucideIcons.scanQrCode),
                label: Text('stock.receipt.scanCode'.tr),
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
                      '${controller.expiryWarning(controller.lines[i].expiresAt) ? ' · ⚠ ${'stock.receipt.expiryWarn'.tr}' : ''}',
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
          () => Text(
            '${'stock.receipt.total'.tr}: ${formatVnd(controller.total.toString())}',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _scan(BuildContext context, ReceiptFormController c) async {
    final codes =
        (await Get.toNamed(Routes.scan, arguments: {'continuous': true}))
            as List<String>?;
    final code = codes?.firstOrNull;
    if (code == null) return;
    final supply = await c.scanManufacturerCode(code);
    if (supply == null || !context.mounted) return;
    await _lineSheet(context, c, supply);
  }

  Future<void> _pickSupply(
    BuildContext context,
    ReceiptFormController c,
  ) async {
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
    await _lineSheet(
      context,
      c,
      SupplySummary(id: o.value, code: o.code, name: o.name),
    );
  }

  Future<void> _lineSheet(
    BuildContext context,
    ReceiptFormController c,
    SupplySummary supply,
  ) async {
    await AppSheet.show<void>(
      context,
      builder: (ctx) => SheetForm(
        initial: const {'qty': '1'},
        builder: (context, form) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: '${supply.code} — ${supply.name}'),
            TextField(
              controller: form.field('lot'),
              decoration: InputDecoration(labelText: 'scan.lot.lotNo'.tr),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('expiry'),
              readOnly: true,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) form.field('expiry').text = formatDate(d);
              },
              decoration: InputDecoration(
                labelText: 'scan.lot.expiry'.tr,
                suffixIcon: const Icon(LucideIcons.calendarDays),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            QtyField(
              controller: form.field('qty'),
              label: 'repairs.parts.quantity'.tr,
            ),
            const SizedBox(height: AppSpacing.sm),
            MoneyField(
              controller: form.field('cost'),
              label: 'repairs.parts.unitCost'.tr,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                final cost = MoneyField.raw(form.text('cost'));
                c.addLine(
                  ReceiptLine(
                    supplyId: supply.id,
                    label: '${supply.code} — ${supply.name}',
                    lotNo: form.textOrNull('lot'),
                    expiresAt: _iso(form.text('expiry')),
                    quantity: form.text('qty').isEmpty ? '1' : form.text('qty'),
                    unitCost: cost.isEmpty ? '0' : cost,
                  ),
                );
                form.close();
              },
              child: Text('common.add'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step3 extends StatelessWidget {
  const _Step3({required this.controller});

  final ReceiptFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final s in ['passed', 'failed', 'pending'])
                ChoiceChip(
                  label: Text('stock.receipt.qc.$s'.tr),
                  selected: controller.qcStatus.value == s,
                  onSelected: (v) {
                    if (v) controller.qcStatus.value = s;
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller.qcNote,
          decoration: InputDecoration(labelText: 'stock.receipt.qcNote'.tr),
        ),
      ],
    );
  }
}

String? _iso(String display) {
  final parts = display.split('/');
  if (parts.length != 3) return null;
  return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
}
