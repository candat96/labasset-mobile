import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/stock.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/supplies_repository.dart';
import 'lot_card_controller.dart';

/// Bottom sheet "Thẻ lô vật tư" hiển thị sau khi quét mã lô.
class LotCardSheet {
  LotCardSheet._();

  static Future<void> show(StockLotSummary lot) async {
    final context = AppSheet.rootContext;
    if (context == null) return;
    // Controller đăng ký trước khi mở; xoá khi sheet unmount (sau animation
    // đóng) trong [_LotCardViewState.dispose] — không xoá ngay sau `await`.
    Get.put(
      LotCardController(
        lot: lot,
        supplies: Get.find<SuppliesRepository>(),
        stock: Get.find<StockRepository>(),
      ),
      tag: lot.id,
    );
    await AppSheet.show<void>(
      context,
      builder: (ctx) => _LotCardView(tag: lot.id),
    );
  }
}

class _LotCardView extends StatefulWidget {
  const _LotCardView({required this.tag});

  final String tag;

  @override
  State<_LotCardView> createState() => _LotCardViewState();
}

class _LotCardViewState extends State<_LotCardView> {
  late final LotCardController controller = Get.find<LotCardController>(
    tag: widget.tag,
  );

  @override
  void dispose() {
    Get.delete<LotCardController>(tag: widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lot = controller.lot;
    final expiring = lot.effectiveExpiresAt ?? lot.expiresAt;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('scan.lot.title'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => _row(
              context,
              'scan.lot.supply'.tr,
              controller.supplyLabel.value ?? '…',
            ),
          ),
          _row(context, 'scan.lot.lotNo'.tr, lot.lotNo),
          _row(context, 'scan.lot.warehouse'.tr, lot.warehouseId ?? '—'),
          _row(
            context,
            'scan.lot.qty'.tr,
            formatVnd(lot.available, symbol: false),
          ),
          _row(context, 'scan.lot.expiry'.tr, formatDate(expiring)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'scan.lot.status'.tr,
                  style: theme.textTheme.bodySmall,
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
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => FilledButton.icon(
              onPressed: controller.opening.value ? null : controller.openVial,
              icon: const Icon(Icons.lock_open_outlined),
              label: Text('scan.lot.open'.tr),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.viewSupply,
                  child: Text('scan.lot.viewSupply'.tr),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.issueThisLot,
                  child: Text('scan.lot.issue'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
