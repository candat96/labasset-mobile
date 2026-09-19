import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/stock_extra.dart';
import '../../data/repositories/stock_repository.dart';
import 'receipts_controller.dart';

/// Danh sách phiếu nhập kho.
class ReceiptsView extends GetView<ReceiptsController> {
  const ReceiptsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('stock.receipts.title'.tr),
        actions: [
          IconButton(
            tooltip: 'common.add'.tr,
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed('/stock/receipts/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(
            () => Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final s in [null, 'draft', 'posted', 'cancelled'])
                  ChoiceChip(
                    label: Text(
                      s == null
                          ? 'repairs.segment.all'.tr
                          : 'status.receipt.$s'.tr,
                    ),
                    selected: controller.statusFilter.value == s,
                    onSelected: (_) => controller.setStatus(s),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value && controller.items.isEmpty) {
                return const LoadingList();
              }
              if (controller.error.value != null && controller.items.isEmpty) {
                return ErrorState(
                  error: controller.error.value!,
                  onRetry: controller.load,
                );
              }
              if (controller.items.isEmpty) {
                return EmptyState(
                  icon: Icons.move_to_inbox_outlined,
                  title: 'common.empty'.tr,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final r = controller.items[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${r.code} · ${r.totalAmount == '0' ? '' : formatVnd(r.totalAmount)}',
                        ),
                        subtitle: Text(
                          '${'stock.receipt.type.${r.type}'.tr}'
                          '${r.invoiceNo == null ? '' : ' · ${r.invoiceNo}'}'
                          '${r.receivedAt == null ? '' : ' · ${formatDate(r.receivedAt)}'}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: StatusBadge(
                          tone: switch (r.status) {
                            'posted' => StatusTone.success,
                            'cancelled' => StatusTone.danger,
                            _ => StatusTone.warning,
                          },
                          label: 'status.receipt.${r.status}'.tr,
                        ),
                        onTap: () async {
                          await Get.toNamed('/stock/receipts/${r.id}');
                          await controller.load();
                        },
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Chi tiết phiếu nhập: ghi sổ / QC / huỷ / PDF.
class ReceiptDetailView extends StatefulWidget {
  const ReceiptDetailView({super.key, required this.id});

  final String id;

  @override
  State<ReceiptDetailView> createState() => _ReceiptDetailViewState();
}

class _ReceiptDetailViewState extends State<ReceiptDetailView> {
  final Rxn<StockReceipt> receipt = Rxn<StockReceipt>();
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  StockRepository get repo => Get.find<StockRepository>();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      receipt.value = await repo.receipt(widget.id);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _post() async {
    try {
      await repo.postReceipt(widget.id);
      AppSnackbar.success('stock.receipt.posted'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<void> _qc() async {
    try {
      await repo.qcReceipt(widget.id, status: 'passed');
      AppSnackbar.success('stock.receipt.qcSaved'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<void> _cancel() async {
    try {
      await repo.cancelReceipt(widget.id);
      AppSnackbar.success('stock.receipt.cancelled'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<void> _pdf() async {
    try {
      final bytes = await repo.receiptPdf(widget.id);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/phieu-nhap-${widget.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (loading.value && receipt.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('stock.receipts.title'.tr)),
          body: const LoadingList(),
        );
      }
      final err = error.value;
      if (err != null && receipt.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('stock.receipts.title'.tr)),
          body: ErrorState(error: err, onRetry: load),
        );
      }
      final r = receipt.value!;
      return Scaffold(
        appBar: AppBar(
          title: Text(r.code),
          actions: [
            IconButton(
              tooltip: 'repairs.report.open'.tr,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _pdf,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'stock.receipt.type.${r.type}'.tr,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        StatusBadge(
                          tone: r.status == 'posted'
                              ? StatusTone.success
                              : r.status == 'cancelled'
                              ? StatusTone.danger
                              : StatusTone.warning,
                          label: 'status.receipt.${r.status}'.tr,
                        ),
                      ],
                    ),
                    Text(
                      '${'stock.receipt.total'.tr}: ${formatVnd(r.totalAmount)}',
                    ),
                    Text('QC: ${r.qcStatus}'),
                    if (r.invoiceNo != null)
                      Text('${'stock.receipt.invoiceNo'.tr}: ${r.invoiceNo}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in r.items)
              Card(
                child: ListTile(
                  title: Text(item.supplyId),
                  subtitle: Text(
                    '${'repairs.parts.quantity'.tr}: ${item.quantity}'
                    '${item.lotNo == null ? '' : ' · ${'scan.lot.lotNo'.tr}: ${item.lotNo}'}'
                    '${item.expiresAt == null ? '' : ' · ${formatDate(item.expiresAt)}'}',
                  ),
                  trailing: Text(formatVnd(item.unitCost)),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (r.status == 'draft')
              FilledButton.icon(
                onPressed: _post,
                icon: const Icon(Icons.check),
                label: Text('stock.receipt.post'.tr),
              ),
            if (r.status == 'posted' && r.qcStatus == 'pending')
              OutlinedButton.icon(
                onPressed: _qc,
                icon: const Icon(Icons.verified_outlined),
                label: Text('stock.receipt.qc'.tr),
              ),
            if (r.status == 'posted')
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: _cancel,
                icon: const Icon(Icons.cancel_outlined),
                label: Text('stock.receipt.cancel'.tr),
              ),
          ],
        ),
      );
    });
  }
}
