import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/signing.dart';
import '../../data/repositories/signing_repository.dart';
import 'sign_document_sheet.dart';

/// Khối "Bản đã ký" cho màn chi tiết chứng từ: liệt kê bản đã ký kèm nút
/// mở/tải và nút ký số.
class SignedDocumentsSection extends StatefulWidget {
  const SignedDocumentsSection({
    super.key,
    required this.repo,
    required this.docType,
    required this.id,
    this.slots,
  });

  final SigningRepository repo;
  final String docType;
  final String id;
  final List<String>? slots;

  @override
  State<SignedDocumentsSection> createState() => _SignedDocumentsSectionState();
}

class _SignedDocumentsSectionState extends State<SignedDocumentsSection> {
  List<SignedDocument> _documents = const [];
  Object? _error;
  bool _loading = true;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await widget.repo.signedDocuments(widget.docType, widget.id);
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _sign() async {
    final result = await SignDocumentSheet.show(
      context,
      repo: widget.repo,
      docType: widget.docType,
      id: widget.id,
    );
    if (result != null) await _load();
  }

  Future<void> _open(SignedDocument doc) async {
    if (_opening) return;
    final uri = Uri.tryParse(doc.url);
    if (uri == null) return;
    setState(() => _opening = true);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) AppSnackbar.info('common.error'.tr);
    } catch (_) {
      AppSnackbar.info('common.error'.tr);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'signing.signedTitle'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_error != null)
            ErrorState(error: _error!, onRetry: _load)
          else if (_documents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'signing.signedEmpty'.tr,
                style: context.appText.caption,
              ),
            )
          else
            for (final doc in _documents) _SignedRow(doc: doc, onOpen: _open),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            label: 'signing.sign'.tr,
            icon: LucideIcons.penLine,
            expand: true,
            onPressed: _sign,
          ),
        ],
      ),
    );
  }
}

class _SignedRow extends StatelessWidget {
  const _SignedRow({required this.doc, required this.onOpen});
  final SignedDocument doc;
  final Future<void> Function(SignedDocument) onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(LucideIcons.fileCheck2, size: 20, color: context.status.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.label ?? doc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appText.bodyStrong,
                ),
                Text(
                  '${'signing.signedAt'.tr}: ${formatDateTime(doc.signedAt)}',
                  style: context.appText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton.soft(
            label: 'signing.signedOpen'.tr,
            icon: LucideIcons.download,
            onPressed: () => onOpen(doc),
          ),
        ],
      ),
    );
  }
}
