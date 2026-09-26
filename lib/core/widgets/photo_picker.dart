import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../services/attachment_service.dart';
import '../theme/tokens.dart';
import 'app_sheet.dart';

/// Chọn ảnh dùng chung: thư viện **chọn nhiều ảnh một lúc**, camera **chụp
/// liên tiếp** (chụp xong hỏi chụp tiếp).
class PhotoPicker {
  PhotoPicker._();

  /// Sheet chọn nguồn ảnh (chụp / thư viện).
  static Future<ImageSource?> sourceSheet(BuildContext context) =>
      AppSheet.show<ImageSource>(
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
              subtitle: Text('attachment.galleryMulti'.tr),
              onTap: () => AppSheet.close(ctx, ImageSource.gallery),
            ),
          ],
        ),
      );

  /// Chọn ảnh theo [source] (đã nén, chưa upload).
  static Future<List<PickedImage>> pick(
    BuildContext context,
    ImageSource source,
  ) async {
    final service = Get.find<AttachmentService>();
    if (source == ImageSource.gallery) return service.pickImageBytesMulti();
    final out = <PickedImage>[];
    while (true) {
      final one = await service.pickImageBytes(source: ImageSource.camera);
      if (one == null) break;
      out.add(one);
      if (!context.mounted || !await _askTakeMore(context)) break;
    }
    return out;
  }

  /// Mở sheet nguồn rồi chọn ảnh (nút "Thêm ảnh").
  static Future<List<PickedImage>> pickWithSource(BuildContext context) async {
    final source = await sourceSheet(context);
    if (source == null || !context.mounted) return const [];
    return pick(context, source);
  }

  static Future<bool> _askTakeMore(BuildContext context) async {
    final more = await AppSheet.show<bool>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'attachment.takeMore'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => AppSheet.close(ctx, true),
              child: Text('attachment.takeMoreYes'.tr),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => AppSheet.close(ctx, false),
              child: Text('common.done'.tr),
            ),
          ],
        ),
      ),
    );
    return more ?? false;
  }
}
