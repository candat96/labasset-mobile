import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';

import '../theme/tokens.dart';
import 'app_sheet.dart';
import 'app_snackbar.dart';

/// Ký tay → PNG (Uint8List) để upload.
class SignaturePad {
  SignaturePad._();

  /// Mở sheet ký, trả PNG hoặc null nếu huỷ. Controller do sheet sở hữu và
  /// huỷ khi sheet unmount (không huỷ ngay sau `await`).
  static Future<Uint8List?> show(BuildContext context, {String? title}) {
    return AppSheet.show<Uint8List>(
      context,
      builder: (ctx) => _SignatureSheet(title: title),
    );
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

class _SignatureSheet extends StatefulWidget {
  const _SignatureSheet({this.title});

  final String? title;

  @override
  State<_SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<_SignatureSheet> {
  final SignatureController controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

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
            widget.title ?? 'signature.title'.tr,
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
                      AppSnackbar.info('signature.empty'.tr);
                      return;
                    }
                    if (context.mounted) AppSheet.close(context, png);
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
