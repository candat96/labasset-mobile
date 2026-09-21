import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/qty_field.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/stock.dart';
import '../../data/repositories/departments_repository.dart';
import 'supply_detail_controller.dart';

/// Màn Vật tư: tồn theo kho/lô + thao tác lô.
class SupplyDetailView extends GetView<SupplyDetailController> {
  const SupplyDetailView({super.key});

  @override
  String? get tag => Get.parameters['id'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value && controller.supply.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('stock.supply.title'.tr)),
          body: const LoadingList(),
        );
      }
      final err = controller.error.value;
      if (err != null && controller.supply.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('stock.supply.title'.tr)),
          body: ErrorState(error: err, onRetry: controller.load),
        );
      }
      final s = controller.supply.value!;
      return Scaffold(
        appBar: AppBar(title: Text(s.code)),
        body: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              SectionCard(
                title: s.name,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${'stock.supply.code'.tr}: ${s.code}'),
                    if (controller.forecast.value != null)
                      Text(
                        '${'equipment.supply.runway'.tr}: '
                        '${'equipment.supply.daysLeft'.trParams({'days': controller.forecast.value!.daysLeft.toString()})}'
                        ' (${controller.forecast.value!.basis})',
                        style: TextStyle(color: context.status.info),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'stock.supply.balances'.tr,
                child: Column(
                  children: [
                    for (final b
                        in controller.stockInfo.value?.balances ?? const [])
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(b.warehouseName ?? b.warehouseId),
                        subtitle: Text(
                          '${'stock.supply.onHand'.tr}: ${formatVnd(b.qtyOnHand, symbol: false)}'
                          ' · ${'stock.supply.reserved'.tr}: ${formatVnd(b.qtyReserved, symbol: false)}',
                        ),
                        trailing: Text(
                          formatVnd(b.available, symbol: false),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'stock.supply.lots'.tr,
                child: Column(
                  children: [
                    for (final l
                        in controller.stockInfo.value?.lots ?? const [])
                      _LotTile(controller: controller, lot: l),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'stock.supply.machines'.tr,
                child: Column(
                  children: [
                    for (final m in controller.machines)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${m.code} — ${m.name}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Get.toNamed(Routes.equipment(m.id)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      );
    });
  }
}

class _LotTile extends StatelessWidget {
  const _LotTile({required this.controller, required this.lot});

  final SupplyDetailController controller;
  final StockLotSummary lot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiring =
        lot.expiresAt != null &&
        (DateTime.tryParse(
              lot.expiresAt!,
            )?.isBefore(DateTime.now().add(const Duration(days: 30))) ??
            false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${'scan.lot.lotNo'.tr}: ${lot.lotNo}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              StatusBadge(
                tone: lot.status == 'available'
                    ? StatusTone.success
                    : lot.status == 'expired'
                    ? StatusTone.danger
                    : StatusTone.warning,
                label: 'status.lot.${lot.status}'.tr,
              ),
            ],
          ),
          Text(
            '${'stock.supply.onHand'.tr}: ${formatVnd(lot.qtyOnHand, symbol: false)}'
            ' · ${'stock.supply.available'.tr}: ${formatVnd(lot.available, symbol: false)}',
            style: theme.textTheme.bodySmall,
          ),
          if (lot.expiresAt != null)
            Text(
              '${'scan.lot.expiry'.tr}: ${formatDate(lot.expiresAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: expiring ? context.status.warning : null,
              ),
            ),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              TextButton(
                onPressed: () => _openVial(context, controller, lot),
                child: Text('scan.lot.open'.tr),
              ),
              TextButton(
                onPressed: () => _quickIssue(context, controller, lot),
                child: Text('scan.lot.issue'.tr),
              ),
              if (controller.isAdmin)
                TextButton(
                  onPressed: () => _adjust(context, controller, lot),
                  child: Text('stock.adjust.title'.tr),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _openVial(
  BuildContext context,
  SupplyDetailController c,
  StockLotSummary lot,
) async {
  final ok = await ConfirmSheet.show(
    context,
    title: 'scan.lot.open'.tr,
    description: 'stock.lot.openConfirm'.tr,
  );
  if (ok) await c.openLot(lot);
}

Future<void> _adjust(
  BuildContext context,
  SupplyDetailController c,
  StockLotSummary lot,
) async {
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      initial: {'qty': lot.qtyOnHand},
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'stock.adjust.title'.tr),
          QtyField(
            controller: form.field('qty'),
            label: 'stock.adjust.newQty'.tr,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: form.field('reason'),
            decoration: InputDecoration(
              labelText: 'stock.adjust.reason'.tr,
              errorText: form.error('reason'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: form.busy
                ? null
                : () async {
                    if (form.text('reason').isEmpty) {
                      form.setError('reason', 'common.required'.tr);
                      return;
                    }
                    form.setBusy(true);
                    final ok = await c.adjustLot(
                      lot,
                      newQty: form.text('qty'),
                      reason: form.text('reason'),
                    );
                    form.setBusy(false);
                    if (ok) form.close();
                  },
            child: Text('common.save'.tr),
          ),
        ],
      ),
    ),
  );
}

Future<void> _quickIssue(
  BuildContext context,
  SupplyDetailController c,
  StockLotSummary lot,
) async {
  final departments = Get.find<DepartmentsRepository>();
  final list = await departments.list(limit: 50);
  if (list.isEmpty || !context.mounted) return;
  var dept = list.first;
  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      initial: const {'qty': '1'},
      builder: (context, form) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'stock.issue.quick'.tr),
          DropdownButtonFormField<String>(
            initialValue: dept.id,
            decoration: InputDecoration(
              labelText: 'stock.issue.toDepartment'.tr,
            ),
            items: [
              for (final d in list)
                DropdownMenuItem(
                  value: d.id,
                  child: Text('${d.code} — ${d.name}'),
                ),
            ],
            onChanged: (v) => form.refresh(
              () =>
                  dept = list.firstWhere((d) => d.id == v, orElse: () => dept),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
                    final ok = await c.quickIssue(
                      lot: lot,
                      toDepartmentId: dept.id,
                      quantity: form.text('qty').isEmpty
                          ? '1'
                          : form.text('qty'),
                    );
                    form.setBusy(false);
                    if (ok) form.close();
                  },
            child: Text('common.confirm'.tr),
          ),
        ],
      ),
    ),
  );
}
