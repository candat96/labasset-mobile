import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/attachment.dart';
import '../services/attachment_service.dart';
import '../theme/tokens.dart';
import 'app_snackbar.dart';
import 'confirm_sheet.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_list.dart';

/// Nhãn loại tệp theo i18n, fallback chính mã kind.
String attachmentKindLabel(String kind) {
  final key = 'attachment.kind.$kind';
  final label = key.tr;
  return label == key ? kind : label;
}

/// Lưới tệp đính kèm của một đối tượng: xem, thêm (chụp/chọn ảnh), xoá.
class AttachmentsGrid extends StatefulWidget {
  const AttachmentsGrid({
    super.key,
    required this.entityType,
    required this.entityId,
    this.kinds = const ['photo'],
    this.canEdit = true,
    this.downloadable = false,
  });

  final String entityType;
  final String entityId;

  /// Các kind cho phép thêm; kind đầu là mặc định.
  final List<String> kinds;
  final bool canEdit;

  /// Hiện nút "Tải về" trong hộp xem (lưu offline bằng path_provider).
  final bool downloadable;

  @override
  State<AttachmentsGrid> createState() => _AttachmentsGridState();
}

class _AttachmentsGridState extends State<AttachmentsGrid> {
  AttachmentService get _service => Get.find<AttachmentService>();

  List<AttachmentView> _items = const [];
  final Map<String, String> _urls = {};
  bool _loading = true;
  Object? _error;

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
      final items = await _service.attachments.list(
        entityType: widget.entityType,
        entityId: widget.entityId,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      _loadUrls(items).ignore();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadUrls(List<AttachmentView> items) async {
    for (final a in items) {
      if (_urls.containsKey(a.fileId)) continue;
      try {
        final u = await _service.files.url(a.fileId);
        if (!mounted) return;
        setState(() => _urls[a.fileId] = u.url);
      } catch (_) {
        // bỏ qua — tệp vẫn hiển thị dạng biểu tượng
      }
    }
  }

  Future<void> _add() async {
    var kind = widget.kinds.first;
    if (widget.kinds.length > 1) {
      final picked = await Get.bottomSheet<String>(
        SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'attachment.kindLabel'.tr,
                  style: Get.textTheme.titleMedium,
                ),
              ),
              for (final k in widget.kinds)
                ListTile(
                  title: Text(attachmentKindLabel(k)),
                  onTap: () => Get.back(result: k),
                ),
            ],
          ),
        ),
        backgroundColor: Get.theme.colorScheme.surface,
      );
      if (picked == null) return;
      kind = picked;
    }
    final source = await _pickSource();
    if (source == null) return;
    try {
      final result = await _service.addImage(
        entityType: widget.entityType,
        entityId: widget.entityId,
        kind: kind,
        source: source,
      );
      switch (result.status) {
        case AttachmentUploadStatus.uploaded:
          AppSnackbar.success('attachment.uploaded'.tr);
          await _load();
        case AttachmentUploadStatus.queued:
          AppSnackbar.info('attachment.queued'.tr);
        case AttachmentUploadStatus.cancelled:
          break;
      }
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<ImageSource?> _pickSource() => Get.bottomSheet<ImageSource>(
    SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text('common.fromCamera'.tr),
            onTap: () => Get.back(result: ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('common.fromGallery'.tr),
            onTap: () => Get.back(result: ImageSource.gallery),
          ),
        ],
      ),
    ),
    backgroundColor: Get.theme.colorScheme.surface,
  );

  Future<void> _download(String url, AttachmentView a) async {
    try {
      await _service.files.downloadTo(
        url,
        a.displayName.isNotEmpty ? a.displayName : 'attachment-${a.id}',
      );
      AppSnackbar.success('attachment.downloaded'.tr);
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  Future<void> _open(AttachmentView a) async {
    final url = _urls[a.fileId];
    if (url == null) {
      try {
        final u = await _service.files.url(a.fileId);
        if (!mounted) return;
        setState(() => _urls[a.fileId] = u.url);
        return await _open(a);
      } catch (e) {
        AppSnackbar.error(e);
        return;
      }
    }
    if (!mounted) return;
    if (a.isImage) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InteractiveViewer(
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined, size: 64),
                ),
              ),
              OverflowBar(
                children: [
                  if (widget.downloadable)
                    TextButton(
                      onPressed: () => _download(url, a),
                      child: Text('attachment.download'.tr),
                    ),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('common.close'.tr),
                  ),
                  if (widget.canEdit)
                    TextButton(
                      onPressed: () {
                        Get.back();
                        _delete(a);
                      },
                      child: Text(
                        'common.delete'.tr,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      if (widget.downloadable) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              a.displayName.isNotEmpty
                  ? a.displayName
                  : attachmentKindLabel(a.kind),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  _download(url, a);
                },
                child: Text('attachment.download'.tr),
              ),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  AppSnackbar.info('common.copied'.tr);
                },
                child: Text('common.copy'.tr),
              ),
            ],
          ),
        );
        return;
      }
      await Clipboard.setData(ClipboardData(text: url));
      AppSnackbar.info('common.copied'.tr);
    }
  }

  Future<void> _delete(AttachmentView a) async {
    final ok = await ConfirmSheet.show(
      title: 'attachment.deleteConfirm'.tr,
      destructive: true,
    );
    if (!ok) return;
    try {
      await _service.attachments.delete(a.id);
      AppSnackbar.success('attachment.deleted'.tr);
      await _load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'attachment.title'.tr,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (widget.canEdit)
              IconButton(
                tooltip: 'attachment.add'.tr,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _add,
              ),
          ],
        ),
        if (_loading)
          const SizedBox(height: 120, child: LoadingList(rows: 1, height: 100))
        else if (_error != null)
          ErrorState(error: _error!, onRetry: _load)
        else if (_items.isEmpty)
          EmptyState(
            icon: Icons.attach_file_outlined,
            title: 'attachment.empty'.tr,
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final a in _items) _tile(a)],
          ),
      ],
    );
  }

  Widget _tile(AttachmentView a) {
    final theme = Theme.of(context);
    final url = _urls[a.fileId];
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => _open(a),
      onLongPress: widget.canEdit ? () => _delete(a) : null,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                width: 96,
                height: 96,
                child: a.isImage && url != null
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined, size: 32),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.insert_drive_file_outlined),
                      ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              a.displayName.isNotEmpty
                  ? a.displayName
                  : attachmentKindLabel(a.kind),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
