import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sheet.dart';
import 'transfer_form_controller.dart';

/// Chuyển kho `/stock/transfers/new`.
class TransferFormView extends GetView<TransferFormController> {
  const TransferFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('stock.transfer.title'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Obx(
            () => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.warehouse),
              title: Text(
                controller.fromWarehouse.value == null
                    ? 'stock.transfer.from'.tr
                    : controller.fromWarehouse.value!.name,
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () async {
                final d = await controller.pickWarehouse(
                  context,
                  'stock.transfer.from'.tr,
                );
                if (d != null) controller.setFrom(d);
              },
            ),
          ),
          Obx(
            () => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.warehouse),
              title: Text(
                controller.toWarehouse.value == null
                    ? 'stock.transfer.to'.tr
                    : controller.toWarehouse.value!.name,
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () async {
                final d = await controller.pickWarehouse(
                  context,
                  'stock.transfer.to'.tr,
                );
                if (d != null) controller.setTo(d);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.soft(
            onPressed: () => _scanContinuous(context),
            icon: LucideIcons.scanQrCode,
            label: 'stock.transfer.scanLots'.tr,
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => Column(
              children: [
                for (var i = 0; i < controller.lines.length; i++)
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      title: Text(
                        '${'scan.lot.lotNo'.tr}: ${controller.lines[i].lotNo}',
                      ),
                      subtitle: Text(
                        '${'repairs.parts.quantity'.tr}: ${controller.lines[i].quantity}',
                      ),
                      trailing: AppIconButton(
                        tone: AppButtonTone.danger,
                        icon: LucideIcons.x,
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
            () => AppButton.primary(
              onPressed: controller.submitting.value ? null : controller.submit,
              icon: LucideIcons.arrowRightLeft,
              label: 'stock.transfer.submit'.tr,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanContinuous(BuildContext context) async {
    final codes =
        (await Get.toNamed(Routes.scan, arguments: {'continuous': true}))
            as List<String>?;
    if (codes == null || codes.isEmpty) return;
    for (final code in codes) {
      final lot = await controller.findLot(code);
      if (lot == null) continue;
      if (!context.mounted) return;
      final qty = await AppDialog.prompt(
        context,
        title: '${'scan.lot.lotNo'.tr}: ${lot.lotNo}',
        label: 'repairs.parts.quantity'.tr,
        initial: '1',
        confirmLabel: 'common.add'.tr,
      );
      if (qty == null) continue;
      controller.addLine(lot, qty.isEmpty ? '1' : qty);
    }
  }
}
