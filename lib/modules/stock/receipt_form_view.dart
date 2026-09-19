import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
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
                          icon: const Icon(Icons.save_outlined),
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
            trailing: const Icon(Icons.chevron_right),
            onTap: controller.pickWarehouse,
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
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.pickSupplier,
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
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.pickFromDepartment,
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
                icon: const Icon(Icons.qr_code_scanner),
                label: Text('stock.receipt.scanCode'.tr),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickSupply(context, controller),
                icon: const Icon(Icons.list_alt_outlined),
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
                      icon: const Icon(Icons.close),
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
    final codes = await Get.toNamed<List<String>>(
      Routes.scan,
      arguments: {'continuous': true},
    );
    final code = codes?.firstOrNull;
    if (code == null) return;
    final supply = await c.scanManufacturerCode(code);
    if (supply == null) return;
    await _lineSheet(c, supply);
  }

  Future<void> _pickSupply(
    BuildContext context,
    ReceiptFormController c,
  ) async {
    final selection = await PickerSheet.show<String>(
      title: 'stock.receipt.pickSupply'.tr,
      loader: (q) async {
        final page = await c.supplies.list(q: q, limit: 20);
        return [
          for (final s in page.items)
            PickerOption(value: s.id, code: s.code, name: s.name),
        ];
      },
    );
    final o = selection?.option;
    if (o == null) return;
    await _lineSheet(c, SupplySummary(id: o.value, code: o.code, name: o.name));
  }

  Future<void> _lineSheet(ReceiptFormController c, SupplySummary supply) async {
    final qty = TextEditingController(text: '1');
    final lot = TextEditingController();
    final expiry = TextEditingController();
    final cost = TextEditingController();
    await Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom:
                MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${supply.code} — ${supply.name}',
                style: Get.theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: lot,
                decoration: InputDecoration(labelText: 'scan.lot.lotNo'.tr),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: expiry,
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) expiry.text = formatDate(d);
                },
                decoration: InputDecoration(
                  labelText: 'scan.lot.expiry'.tr,
                  suffixIcon: const Icon(Icons.event_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              QtyField(controller: qty, label: 'repairs.parts.quantity'.tr),
              const SizedBox(height: AppSpacing.sm),
              MoneyField(controller: cost, label: 'repairs.parts.unitCost'.tr),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  final iso = _iso(expiry.text);
                  c.addLine(
                    ReceiptLine(
                      supplyId: supply.id,
                      label: '${supply.code} — ${supply.name}',
                      lotNo: lot.text.trim().isEmpty ? null : lot.text.trim(),
                      expiresAt: iso,
                      quantity: qty.text.trim().isEmpty ? '1' : qty.text.trim(),
                      unitCost: MoneyField.raw(cost.text).isEmpty
                          ? '0'
                          : MoneyField.raw(cost.text),
                    ),
                  );
                  Get.back();
                },
                child: Text('common.add'.tr),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Get.theme.colorScheme.surface,
    );
    qty.dispose();
    lot.dispose();
    expiry.dispose();
    cost.dispose();
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
