import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/attachment_service.dart';
import '../../../core/services/pdf_file_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
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
          // Ảnh đã có mục "Ảnh tình trạng" riêng → không hiện lặp ở đây.
          hidePhotos: true,
          kinds: const [
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
                icon: const Icon(LucideIcons.pencil),
                label: Text('repairs.sign.technician'.tr),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _sign(context, 'department'),
                icon: const Icon(LucideIcons.pencil),
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
                  icon: const Icon(LucideIcons.fileText),
                  label: Text('common.view'.tr),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: exporting.value
                      ? null
                      : () => _exportReport(share: true),
                  icon: const Icon(LucideIcons.share2),
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
    final png = await SignaturePad.show(context);
    if (png == null || !context.mounted) return;
    final signerName = await AppDialog.prompt(
      context,
      title: 'repairs.sign.signer'.tr,
    );
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
