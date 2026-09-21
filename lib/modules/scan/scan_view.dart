import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import 'scan_controller.dart';

class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  final ScanController controller = Get.find();
  late final MobileScannerController scanner = MobileScannerController(
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.dataMatrix,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('scan.title'.tr),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'scan.torch'.tr,
              icon: Icon(
                controller.torch.value ? LucideIcons.zap : LucideIcons.zapOff,
              ),
              onPressed: () async {
                await scanner.toggleTorch();
                controller.torch.toggle();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Nền tối cho vùng camera (simulator/không quyền vẫn tối).
                const ColoredBox(color: AppColors.foreground),
                MobileScanner(
                  controller: scanner,
                  onDetect: (capture) {
                    final raw = capture.barcodes.firstOrNull?.rawValue;
                    controller.onDetected(raw);
                  },
                  errorBuilder: (context, error) => Center(
                    child: SizedBox(
                      width: 200,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.onPrimary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.cameraOff,
                              size: 26,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'scan.cameraDenied'.tr,
                            textAlign: TextAlign.center,
                            style: context.appText.body.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryDark,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.hero),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.lg,
                  child: Text(
                    'scan.hint'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                if (controller.continuous)
                  Positioned(
                    top: AppSpacing.md,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Obx(
                        () => Chip(
                          backgroundColor: theme.colorScheme.surface,
                          avatar: const Icon(Icons.qr_code_scanner, size: 18),
                          label: Text(
                            '${'scan.count'.tr}: ${controller.scanCount.value}',
                          ),
                        ),
                      ),
                    ),
                  ),
                Obx(
                  () => controller.busy.value
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (controller.continuous) _ContinuousPanel(controller: controller),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(
                    () => controller.message.value == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              controller.message.value!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.manual,
                          decoration: InputDecoration(
                            labelText: 'scan.manual'.tr,
                            hintText: 'scan.manualHint'.tr,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => controller.submitManual(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Obx(
                        () => SizedBox(
                          width: 116,
                          child: GradientButton(
                            label: controller.continuous
                                ? 'common.add'.tr
                                : 'scan.lookup'.tr,
                            onPressed: controller.busy.value
                                ? null
                                : controller.submitManual,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Obx(() {
                    if (controller.history.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'scan.history'.tr,
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              for (final code in controller.history)
                                ActionChip(
                                  label: Text(code),
                                  onPressed: () {
                                    controller.manual.text = code;
                                    controller.submitManual();
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bộ đếm + danh sách mã vừa quét + nút "Xong" của chế độ quét liên tục.
class _ContinuousPanel extends StatelessWidget {
  const _ContinuousPanel({required this.controller});

  final ScanController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'scan.recent'.tr,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: controller.finish,
                icon: const Icon(Icons.check),
                label: Text('scan.done'.tr),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 40,
            child: Obx(
              () => controller.recentCodes.isEmpty
                  ? Text('scan.hint'.tr, style: theme.textTheme.bodySmall)
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.recentCodes.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (_, i) {
                        final code = controller.recentCodes[i];
                        return InputChip(
                          label: Text(code),
                          onDeleted: () => controller.removeCode(code),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
