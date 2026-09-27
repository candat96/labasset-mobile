import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/field_shell.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/qty_field.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/stock.dart';
import '../../data/models/supply.dart';
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
              ..._profileSections(context, controller, s),
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
                        title: Text(
                          b.warehouseName ?? 'stock.warehouse.unknown'.tr,
                        ),
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
                        trailing: const Icon(LucideIcons.chevronRight),
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

/// Các khối hồ sơ vật tư (chỉ đọc): pháp lý, BHYT, thầu, quy đổi, hạn dùng,
/// vật tư thay thế. Khối rỗng bị ẩn.
List<Widget> _profileSections(
  BuildContext context,
  SupplyDetailController c,
  SupplySummary s,
) {
  final parts = <Widget?>[
    _infoSection(context, 'stock.supply.legal'.tr, [
      _Field('stock.supply.circulationNumber'.tr, s.circulationNumber),
      _Field(
        'stock.supply.circulationValidTo'.tr,
        _validToText(context, s.circulationValidTo),
        color: _validToColor(context, s.circulationValidTo),
      ),
      _Field(
        'stock.supply.riskClass'.tr,
        s.riskClass == null
            ? null
            : 'stock.supply.riskClassValue'.trParams({'class': s.riskClass!}),
      ),
      _Field('stock.supply.countryOfOrigin'.tr, s.countryOfOrigin),
    ]),
    _infoSection(context, 'stock.supply.insurance'.tr, [
      _Field('stock.supply.insuranceCode'.tr, s.insuranceCode),
      _Field('stock.supply.insuranceName'.tr, s.insuranceName),
      _Field(
        'stock.supply.insuranceRate'.tr,
        s.insuranceRate == null ? null : '${formatDecimal(s.insuranceRate)}%',
      ),
      _Field('stock.supply.insurancePrice'.tr, formatVnd(s.insurancePrice)),
    ]),
    _infoSection(context, 'stock.supply.bid'.tr, [
      _Field('stock.supply.bidPackage'.tr, s.bidPackage),
      _Field('stock.supply.bidDecisionNo'.tr, s.bidDecisionNo),
      _Field('stock.supply.bidPrice'.tr, formatVnd(s.bidPrice)),
      _Field(
        'stock.supply.bidValidTo'.tr,
        _validToText(context, s.bidValidTo),
        color: _validToColor(context, s.bidValidTo),
      ),
    ]),
    _ConversionSection(controller: c, supply: s),
    _infoSection(context, 'stock.supply.shelfLife'.tr, [
      _Field(
        'stock.supply.minShelfLifeDays'.tr,
        s.minShelfLifeDays == null
            ? null
            : 'stock.supply.shelfLifeDays'.trParams({
                'days': s.minShelfLifeDays.toString(),
              }),
      ),
    ]),
    _SubstitutesSection(controller: c),
  ];

  final visible = parts.whereType<Widget>().toList();
  return [
    for (var i = 0; i < visible.length; i++) ...[
      if (i > 0) const SizedBox(height: AppSpacing.md),
      visible[i],
    ],
  ];
}

/// Khối nhãn/giá trị chỉ đọc; trả `null` khi mọi trường đều rỗng.
Widget? _infoSection(BuildContext context, String title, List<_Field> fields) {
  final visible = fields
      .where((f) => f.value != null && f.value!.isNotEmpty)
      .toList();
  if (visible.isEmpty) return null;
  return SectionCard(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _ReadOnlyField(
            label: visible[i].label,
            value: visible[i].value,
            valueColor: visible[i].color,
          ),
        ],
      ],
    ),
  );
}

/// Diễn giải hạn hiệu lực kèm cảnh báo: đã qua → đỏ, ≤ 60 ngày → vàng.
String? _validToText(BuildContext context, String? date) {
  if (date == null || date.isEmpty) return null;
  final base = formatDate(date);
  if (base.isEmpty) return null;
  return switch (validityTone(date)) {
    ValidityTone.expired => '$base (${'stock.supply.validTo.expired'.tr})',
    ValidityTone.soon => '$base (${'stock.supply.validTo.soon'.tr})',
    ValidityTone.none => base,
  };
}

Color? _validToColor(BuildContext context, String? date) =>
    switch (validityTone(date)) {
      ValidityTone.expired => context.status.danger,
      ValidityTone.soon => context.status.warning,
      ValidityTone.none => null,
    };

class _Field {
  const _Field(this.label, this.value, {this.color});
  final String label;
  final String? value;
  final Color? color;
}

/// Một dòng nhãn/giá trị chỉ đọc theo chuẩn ô nhập (nhãn trên, giá trị dưới).
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String? value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label),
        Text(
          value == null || value!.isEmpty
              ? 'stock.supply.valueEmpty'.tr
              : value!,
          style: context.appText.body.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Quy đổi đơn vị mua ↔ đơn vị dùng kèm diễn giải "1 Thùng = 100 Cái".
class _ConversionSection extends StatelessWidget {
  const _ConversionSection({required this.controller, required this.supply});

  final SupplyDetailController controller;
  final SupplySummary supply;

  @override
  Widget build(BuildContext context) {
    final label = controller.conversionLabel;
    final fields = <_Field>[
      if (supply.purchaseUnitId != null)
        _Field(
          'stock.supply.purchaseUnit'.tr,
          controller.unitName(supply.purchaseUnitId),
        ),
      if (supply.conversionFactor != null)
        _Field(
          'stock.supply.conversionFactor'.tr,
          formatDecimal(supply.conversionFactor),
        ),
    ].where((f) => f.value != null && f.value!.isNotEmpty).toList();
    if (fields.isEmpty && label == null) return const SizedBox.shrink();

    final children = <Widget>[
      for (final f in fields) ...[
        _ReadOnlyField(label: f.label, value: f.value),
        if (f != fields.last || label != null)
          const SizedBox(height: AppSpacing.md),
      ],
      if (label != null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.arrowRightLeft,
              size: 16,
              color: context.status.info,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: context.appText.bodyStrong.copyWith(
                  color: context.status.info,
                ),
              ),
            ),
          ],
        ),
    ];
    return SectionCard(
      title: 'stock.supply.conversion'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Danh sách vật tư thay thế (chỉ đọc, chạm để mở vật tư đó).
class _SubstitutesSection extends StatelessWidget {
  const _SubstitutesSection({required this.controller});

  final SupplyDetailController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.substitutes;
    return SectionCard(
      title: 'stock.supply.substitutes'.tr,
      child: items.isEmpty
          ? Text(
              'stock.supply.substitutesEmpty'.tr,
              style: context.appText.label,
            )
          : Column(
              children: [
                for (final sub in items)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      LucideIcons.replace,
                      color: context.status.info,
                    ),
                    title: Text(sub.name),
                    subtitle: Text(
                      [
                        sub.code,
                        if (sub.unitName != null && sub.unitName!.isNotEmpty)
                          sub.unitName!,
                        if (sub.notes != null && sub.notes!.isNotEmpty)
                          sub.notes!,
                      ].join(' · '),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => Get.toNamed(Routes.supply(sub.id)),
                  ),
              ],
            ),
    );
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
            spacing: AppSpacing.sm,
            children: [
              AppButton.soft(
                onPressed: () => _openVial(context, controller, lot),
                label: 'scan.lot.open'.tr,
              ),
              AppButton.soft(
                onPressed: () => _quickIssue(context, controller, lot),
                label: 'scan.lot.issue'.tr,
              ),
              if (controller.isAdmin)
                AppButton.soft(
                  onPressed: () => _adjust(context, controller, lot),
                  label: 'stock.adjust.title'.tr,
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
            focusNode: form.focusNode('reason'),
            decoration: InputDecoration(
              labelText: 'stock.adjust.reason'.tr,
              errorText: form.error('reason'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
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
            label: 'common.save'.tr,
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
          AppButton.primary(
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
            label: 'common.confirm'.tr,
          ),
        ],
      ),
    ),
  );
}
