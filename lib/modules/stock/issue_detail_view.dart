import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/format/format.dart';
import '../../core/services/attachment_service.dart';
import '../../core/services/pdf_file_service.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/signature_pad.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/stock_issue.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/supplies_repository.dart';

/// Chi tiết phiếu xuất: ký người nhận, ghi sổ, huỷ, PDF.
class IssueDetailView extends StatefulWidget {
  const IssueDetailView({super.key, required this.id});

  final String id;

  @override
  State<IssueDetailView> createState() => _IssueDetailViewState();
}

class _IssueDetailViewState extends State<IssueDetailView> {
  final Rxn<StockIssue> issue = Rxn<StockIssue>();
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxMap<String, String> supplyLabels = <String, String>{}.obs;
  final RxMap<String, String> lotLabels = <String, String>{}.obs;

  StockRepository get repo => Get.find<StockRepository>();
  SuppliesRepository get supplies => Get.find<SuppliesRepository>();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final loaded = await repo.issue(widget.id);
      await _loadLabels(loaded);
      issue.value = loaded;
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _loadLabels(StockIssue loaded) async {
    for (final item in loaded.items) {
      try {
        final supply = await supplies.byId(item.supplyId);
        supplyLabels[item.supplyId] = '${supply.code} — ${supply.name}';
      } catch (_) {
        supplyLabels[item.supplyId] = 'equipment.supply.unknown'.tr;
      }
      final lotId = item.lotId;
      if (lotId == null) continue;
      try {
        final page = await repo.lots(supplyId: item.supplyId, limit: 100);
        final lot = page.items.where((l) => l.id == lotId).firstOrNull;
        if (lot != null && lot.lotNo.isNotEmpty) lotLabels[lotId] = lot.lotNo;
      } catch (_) {
        // Không hiện UUID nếu API lô tạm thời lỗi.
      }
    }
  }

  Future<void> _sign() async {
    final png = await SignaturePad.show(context);
    if (png == null || !mounted) return;
    final signer = await AppDialog.prompt(
      context,
      title: 'stock.issue.receiver'.tr,
      label: 'repairs.sign.signer'.tr,
    );
    if (signer == null || signer.isEmpty) return;
    try {
      final service = Get.find<AttachmentService>();
      final upload = await service.uploadBytes(
        entityType: 'stock_issue',
        entityId: widget.id,
        kind: 'signature',
        name: 'chu-ky-nhan.png',
        mime: 'image/png',
        bytes: png,
      );
      final fileId = upload.attachment?.fileId;
      if (fileId == null) {
        AppSnackbar.info('attachment.queued'.tr);
        return;
      }
      await repo.updateIssue(widget.id, {
        'receiverSignatureFileId': fileId,
        'receiverName': signer,
      });
      AppSnackbar.success('repairs.sign.saved'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<void> _post() async {
    try {
      await repo.postIssue(widget.id);
      AppSnackbar.success('stock.issue.posted'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<void> _cancel() async {
    try {
      await repo.cancelIssue(widget.id);
      AppSnackbar.success('stock.receipt.cancelled'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<void> _pdf({bool share = false}) async {
    try {
      final bytes = await repo.issuePdf(widget.id);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/phieu-xuat-${widget.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (share) {
        await PdfFileService.share(file);
      } else {
        await PdfFileService.open(file);
      }
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (loading.value && issue.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('stock.issues.title'.tr)),
          body: const LoadingList(),
        );
      }
      final err = error.value;
      if (err != null && issue.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('stock.issues.title'.tr)),
          body: ErrorState(error: err, onRetry: load),
        );
      }
      final x = issue.value!;
      return Scaffold(
        appBar: AppBar(
          title: Text(x.code),
          actions: [
            IconButton(
              tooltip: 'repairs.report.open'.tr,
              icon: const Icon(LucideIcons.fileText),
              onPressed: _pdf,
            ),
            IconButton(
              tooltip: 'common.share'.tr,
              icon: const Icon(LucideIcons.share2),
              onPressed: () => _pdf(share: true),
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
                            'stock.issue.type.${x.type}'.tr,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        StatusBadge(
                          tone: x.status == 'posted'
                              ? StatusTone.success
                              : x.status == 'cancelled'
                              ? StatusTone.danger
                              : StatusTone.warning,
                          label: 'status.receipt.${x.status}'.tr,
                        ),
                      ],
                    ),
                    if (x.fefoWarning)
                      Text(
                        'stock.issue.fefoWarn'.tr,
                        style: TextStyle(color: theme.colorScheme.tertiary),
                      ),
                    if (x.reason != null)
                      Text('${'stock.issue.reason'.tr}: ${x.reason}'),
                    if (x.receiverName != null)
                      Text('${'stock.issue.receiver'.tr}: ${x.receiverName}'),
                    if (x.issuedAt != null)
                      Text(
                        '${'stock.issue.issuedAt'.tr}: ${formatDateTime(x.issuedAt)}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in x.items)
              Card(
                child: ListTile(
                  title: Text(
                    supplyLabels[item.supplyId] ??
                        'equipment.supply.unknown'.tr,
                  ),
                  subtitle: Text(
                    '${'repairs.parts.quantity'.tr}: ${item.quantity}'
                    '${item.lotId == null || lotLabels[item.lotId!] == null ? '' : ' · ${'scan.lot.lotNo'.tr}: ${lotLabels[item.lotId!]}'}',
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (x.status == 'draft') ...[
              OutlinedButton.icon(
                onPressed: _sign,
                icon: Icon(
                  x.receiverSignatureFileId == null
                      ? LucideIcons.pencil
                      : LucideIcons.circleCheck,
                ),
                label: Text(
                  x.receiverSignatureFileId == null
                      ? 'stock.issue.sign'.tr
                      : 'stock.issue.signed'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _post,
                icon: const Icon(LucideIcons.check),
                label: Text('stock.receipt.post'.tr),
              ),
            ],
            if (x.status != 'cancelled')
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: _cancel,
                icon: const Icon(LucideIcons.circleX),
                label: Text('stock.receipt.cancel'.tr),
              ),
          ],
        ),
      );
    });
  }
}
