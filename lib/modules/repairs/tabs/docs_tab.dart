import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/attachment_service.dart';
import '../../../core/services/pdf_file_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/attachments_grid.dart';
import '../../../core/widgets/signature_pad.dart';
import '../../../data/repositories/repairs_repository.dart';

/// Tab "Ảnh & chữ ký" + xuất biên bản PDF.
class DocsTab extends StatefulWidget {
  const DocsTab({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<DocsTab> createState() => _DocsTabState();
}

class _DocsTabState extends State<DocsTab> {
  final RxBool exporting = false.obs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AttachmentsGrid(
          entityType: 'repair_ticket',
          entityId: widget.ticketId,
          kinds: const [
            'photo',
            'video',
            'signature_technician',
            'signature_department',
            'report',
            'other',
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _sign(context, 'technician'),
                icon: const Icon(Icons.draw_outlined),
                label: Text('repairs.sign.technician'.tr),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _sign(context, 'department'),
                icon: const Icon(Icons.draw_outlined),
                label: Text('repairs.sign.department'.tr),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: exporting.value
                      ? null
                      : () => _exportReport(share: false),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text('common.view'.tr),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: exporting.value
                      ? null
                      : () => _exportReport(share: true),
                  icon: const Icon(Icons.share_outlined),
                  label: Text('common.share'.tr),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sign(BuildContext context, String role) async {
    final name = TextEditingController();
    final png = await SignaturePad.show();
    if (png == null) return;
    final signerName = await Get.dialog<String>(
      AlertDialog(
        title: Text('repairs.sign.signer'.tr),
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
    if (signerName == null || signerName.isEmpty) return;
    try {
      final service = Get.find<AttachmentService>();
      final upload = await service.uploadBytes(
        entityType: 'repair_ticket',
        entityId: widget.ticketId,
        kind: role == 'technician'
            ? 'signature_technician'
            : 'signature_department',
        name: 'chu-ky-$role.png',
        mime: 'image/png',
        bytes: png,
      );
      final fileId = upload.attachment?.fileId;
      if (fileId == null) {
        AppSnackbar.info('attachment.queued'.tr);
        return;
      }
      await Get.find<RepairsRepository>().addSignature(
        widget.ticketId,
        role: role,
        signerName: signerName,
        fileId: fileId,
      );
      AppSnackbar.success('repairs.sign.saved'.tr);
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<void> _exportReport({required bool share}) async {
    exporting.value = true;
    try {
      await exportRepairPdf(widget.ticketId, share: share);
    } catch (e) {
      AppSnackbar.error(e);
    } finally {
      exporting.value = false;
    }
  }
}

/// Tải PDF biên bản rồi mở ngoài app hoặc chia sẻ.
Future<void> exportRepairPdf(String ticketId, {bool share = false}) async {
  final bytes = await Get.find<RepairsRepository>().reportPdf(ticketId);
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/bien-ban-$ticketId.pdf');
  await file.writeAsBytes(bytes, flush: true);
  if (share) {
    await PdfFileService.share(file);
  } else {
    await PdfFileService.open(file);
  }
}
