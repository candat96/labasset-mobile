import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format/format.dart';
import '../../core/services/attachment_service.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/signature_pad.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/stock_issue.dart';
import '../../data/repositories/stock_repository.dart';

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
      issue.value = await repo.issue(widget.id);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _sign() async {
    final name = TextEditingController();
    final png = await SignaturePad.show();
    if (png == null) return;
    final signer = await Get.dialog<String>(
      AlertDialog(
        title: Text('stock.issue.receiver'.tr),
        content: TextField(
          controller: name,
          decoration: InputDecoration(labelText: 'repairs.sign.signer'.tr),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
          FilledButton(
            onPressed: () => Get.back(result: name.text.trim()),
            child: Text('common.save'.tr),
          ),
        ],
      ),
    );
    name.dispose();
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

  Future<void> _pdf() async {
    try {
      final bytes = await repo.issuePdf(widget.id);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/phieu-xuat-${widget.id}.pdf');
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
                  title: Text(item.supplyId),
                  subtitle: Text(
                    '${'repairs.parts.quantity'.tr}: ${item.quantity}'
                    '${item.lotId == null ? '' : ' · ${'scan.lot.lotNo'.tr}: ${item.lotId}'}',
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (x.status == 'draft') ...[
              OutlinedButton.icon(
                onPressed: _sign,
                icon: Icon(
                  x.receiverSignatureFileId == null
                      ? Icons.draw_outlined
                      : Icons.check_circle_outline,
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
                icon: const Icon(Icons.check),
                label: Text('stock.receipt.post'.tr),
              ),
            ],
            if (x.status != 'cancelled')
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
