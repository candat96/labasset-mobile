import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';

import '../theme/tokens.dart';

/// Ký tay → PNG (Uint8List) để upload.
class SignaturePad {
  SignaturePad._();

  /// Mở sheet ký, trả PNG hoặc null nếu huỷ.
  static Future<Uint8List?> show({String? title}) async {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    try {
      return await Get.bottomSheet<Uint8List>(
        SafeArea(
          child: _SignatureSheet(controller: controller, title: title),
        ),
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg * 2),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  /// PNG từ pad đang mở (dùng khi nhúng [SignaturePadPanel] trong form).
  static Future<Uint8List?> toPng(SignatureController controller) async {
    if (controller.isEmpty) return null;
    return controller.toPngBytes();
  }
}

/// Pad ký nhúng được trong form/trang.
class SignaturePadPanel extends StatelessWidget {
  const SignaturePadPanel({
    super.key,
    required this.controller,
    this.height = 180,
  });

  final SignatureController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Signature(controller: controller, backgroundColor: Colors.white),
    );
  }
}

class _SignatureSheet extends StatelessWidget {
  const _SignatureSheet({required this.controller, this.title});

  final SignatureController controller;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title ?? 'signature.title'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          SignaturePadPanel(controller: controller, height: 220),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: Text('signature.clear'.tr),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final png = await SignaturePad.toPng(controller);
                    if (png == null) {
                      Get.snackbar(
                        'signature.title'.tr,
                        'signature.empty'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    Get.back(result: png);
                  },
                  icon: const Icon(Icons.check),
                  label: Text('signature.save'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
