import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/attachment.dart';
import '../services/attachment_service.dart';
import '../theme/tokens.dart';
import 'app_sheet.dart';
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
    this.photosOnly = false,
    this.title,
  });

  final String entityType;
  final String entityId;

  /// Các kind cho phép thêm; kind đầu là mặc định.
  final List<String> kinds;
  final bool canEdit;
  final bool photosOnly;
  final String? title;

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
  bool _uploading = false;

  @override
  void didUpdateWidget(covariant AttachmentsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entityType != widget.entityType ||
        oldWidget.entityId != widget.entityId) {
      _items = const [];
      _urls.clear();
      _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entityType = widget.entityType;
    final entityId = widget.entityId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.attachments.list(
        entityType: entityType,
        entityId: entityId,
      );
      if (!mounted ||
          entityType != widget.entityType ||
          entityId != widget.entityId) {
        return;
      }
      setState(() {
        _items = items;
        _loading = false;
      });
      _loadUrls(items).ignore();
    } catch (e) {
      if (!mounted ||
          entityType != widget.entityType ||
          entityId != widget.entityId) {
        return;
      }
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

  Future<void> _add({ImageSource? imageSource}) async {
    if (_uploading) return;
    var kind = widget.kinds.first;
    if (!widget.photosOnly && widget.kinds.length > 1) {
      final picked = await AppSheet.show<String>(
        context,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: 'attachment.kindLabel'.tr),
            for (final k in widget.kinds)
              ListTile(
                title: Text(attachmentKindLabel(k)),
                onTap: () => AppSheet.close(ctx, k),
              ),
          ],
        ),
      );
      if (picked == null) return;
      kind = picked;
    }
    final source = imageSource ?? await _pickSource();
    if (source == null) return;
    if (!mounted) return;
    setState(() => _uploading = true);
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
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<ImageSource?> _pickSource() => AppSheet.show<ImageSource>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: Text('common.fromCamera'.tr),
          onTap: () => AppSheet.close(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: Text('common.fromGallery'.tr),
          onTap: () => AppSheet.close(ctx, ImageSource.gallery),
        ),
      ],
    ),
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
        builder: (ctx) => Dialog(
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
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('common.close'.tr),
                  ),
                  if (widget.canEdit)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
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
          builder: (ctx) => AlertDialog(
            title: Text(
              a.displayName.isNotEmpty
                  ? a.displayName
                  : attachmentKindLabel(a.kind),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
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
      context,
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
    final visibleItems = widget.photosOnly
        ? _items.where((a) => a.kind == 'photo').toList()
        : _items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title ?? 'attachment.title'.tr,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (widget.canEdit && !widget.photosOnly)
              IconButton(
                tooltip: 'attachment.add'.tr,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _uploading ? null : () => _add(),
              ),
          ],
        ),
        if (widget.photosOnly) ...[
          Text('attachment.conditionHint'.tr),
          if (widget.canEdit)
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _add(imageSource: ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text('common.fromCamera'.tr),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _add(imageSource: ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text('common.fromGallery'.tr),
                ),
              ],
            ),
        ],
        if (_uploading) const LinearProgressIndicator(),
        if (_loading)
          const SizedBox(height: 120, child: LoadingList(rows: 1, height: 100))
        else if (_error != null)
          ErrorState(error: _error!, onRetry: _load)
        else if (visibleItems.isEmpty)
          EmptyState(
            icon: Icons.attach_file_outlined,
            title: 'attachment.empty'.tr,
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final a in visibleItems) _tile(a)],
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
