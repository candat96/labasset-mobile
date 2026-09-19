import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/tokens.dart';
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
                controller.torch.value ? Icons.flash_on : Icons.flash_off,
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
                MobileScanner(
                  controller: scanner,
                  onDetect: (capture) {
                    final raw = capture.barcodes.firstOrNull?.rawValue;
                    controller.onDetected(raw);
                  },
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'scan.cameraDenied'.tr,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(AppRadius.lg * 2),
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
                      color: Colors.white,
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
                        () => FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(96, 44),
                          ),
                          onPressed: controller.busy.value
                              ? null
                              : controller.submitManual,
                          child: Text(
                            controller.continuous
                                ? 'common.add'.tr
                                : 'scan.lookup'.tr,
                          ),
                        ),
                      ),
                    ],
                  ),
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
