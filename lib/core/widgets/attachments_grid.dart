import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/attachment.dart';
import '../services/attachment_service.dart';
import '../theme/tokens.dart';
import 'app_buttons.dart';
import 'app_sheet.dart';
import 'app_snackbar.dart';
import 'confirm_sheet.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_list.dart';
import 'photo_grid.dart';
import 'photo_picker.dart';

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
    this.hidePhotos = false,
    this.title,
  });

  final String entityType;
  final String entityId;

  /// Các kind cho phép thêm; kind đầu là mặc định.
  final List<String> kinds;
  final bool canEdit;
  final bool photosOnly;
  final String? title;

  /// Ẩn ảnh (kind `photo`) — dùng cho mục "Tệp đính kèm" khi màn đã có mục
  /// "Ảnh tình trạng" riêng (tránh một ảnh hiện ở hai chỗ).
  final bool hidePhotos;

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
    if (!mounted) return;
    final images = imageSource == null
        ? await PhotoPicker.pickWithSource(context)
        : await PhotoPicker.pick(context, imageSource);
    if (images.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    var uploaded = 0;
    var queued = 0;
    try {
      for (final image in images) {
        try {
          final result = await _service.uploadPicked(
            entityType: widget.entityType,
            entityId: widget.entityId,
            kind: kind,
            picked: image,
          );
          switch (result.status) {
            case AttachmentUploadStatus.uploaded:
              uploaded++;
            case AttachmentUploadStatus.queued:
              queued++;
            case AttachmentUploadStatus.cancelled:
              break;
          }
        } catch (e) {
          AppSnackbar.error(e);
        }
      }
      if (uploaded > 0) {
        AppSnackbar.success(
          'attachment.uploadedCount'.trParams({'n': '$uploaded'}),
        );
        await _load();
      }
      if (queued > 0) {
        AppSnackbar.info('attachment.queuedCount'.trParams({'n': '$queued'}));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

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
                    AppButton.soft(
                      label: 'attachment.download'.tr,
                      onPressed: () => _download(url, a),
                    ),
                  AppButton.soft(
                    label: 'common.close'.tr,
                    tone: AppButtonTone.neutral,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  if (widget.canEdit)
                    AppButton.soft(
                      label: 'common.delete'.tr,
                      tone: AppButtonTone.danger,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _delete(a);
                      },
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
              AppButton.soft(
                label: 'attachment.download'.tr,
                onPressed: () {
                  Navigator.pop(ctx);
                  _download(url, a);
                },
              ),
              AppButton.soft(
                label: 'common.copy'.tr,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  AppSnackbar.info('common.copied'.tr);
                },
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
    final visibleItems = _items
        .where((a) => !widget.photosOnly || a.kind == 'photo')
        .where((a) => !widget.hidePhotos || a.kind != 'photo')
        .toList();
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
              AppIconButton(
                tooltip: 'attachment.add'.tr,
                icon: Icons.add_circle_outline,
                onPressed: _uploading ? null : () => _add(),
              ),
          ],
        ),
        if (widget.photosOnly) ...[
          Text('attachment.conditionHint'.tr),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_uploading) const LinearProgressIndicator(),
        if (_loading)
          const SizedBox(height: 120, child: LoadingList(rows: 1, height: 100))
        else if (_error != null)
          ErrorState(error: _error!, onRetry: _load)
        else if (visibleItems.isEmpty && !widget.canEdit)
          EmptyState(
            icon: Icons.attach_file_outlined,
            title: 'attachment.empty'.tr,
          )
        else
          PhotoGrid(
            tiles: [for (final a in visibleItems) _tile(a)],
            onAdd: widget.canEdit ? () => _add() : null,
            addLabel: 'attachment.addPhotos'.tr,
          ),
      ],
    );
  }

  PhotoGridTile _tile(AttachmentView a) {
    final url = _urls[a.fileId];
    return PhotoGridTile(
      image: a.isImage && url != null ? NetworkImage(url) : null,
      fileLabel: a.displayName.isNotEmpty
          ? a.displayName
          : attachmentKindLabel(a.kind),
      onTap: () => _open(a),
      onRemove: widget.canEdit ? () => _delete(a) : null,
      removeTooltip: 'attachment.deleteConfirm'.tr,
    );
  }
}
