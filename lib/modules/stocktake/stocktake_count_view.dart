import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/attachment_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/segment_tabs.dart';
import '../../core/widgets/qty_field.dart';
import '../../core/stocktake/stocktake_local_store.dart';
import 'stocktake_count_controller.dart';

/// Đếm kiểm kê offline `/stocktakes/:id/count`.
class StocktakeCountView extends GetView<StocktakeCountController> {
  const StocktakeCountView({super.key});

  @override
  String? get tag => Get.parameters['id'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.loading.value && controller.meta.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('stocktake.count'.tr)),
          body: const LoadingList(),
        );
      }
      final err = controller.error.value;
      if (err != null && controller.meta.value == null) {
        return Scaffold(
          appBar: AppBar(title: Text('stocktake.count'.tr)),
          body: ErrorState(error: err, onRetry: controller.load),
        );
      }
      final meta = controller.meta.value;
      return Scaffold(
        appBar: AppBar(
          title: Text(meta?.code ?? 'stocktake.count'.tr),
          actions: [
            IconButton(
              tooltip: 'scan.title'.tr,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _scanContinuous(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final p = controller.progress.value;
                    final counted = controller.counted.length;
                    final total = controller.items.length;
                    final percent =
                        p?.percent ??
                        (total == 0 ? 0 : (counted / total) * 100);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: (percent / 100).clamp(0, 1),
                        ),
                        Text(
                          '$counted/$total (${percent.round()}%)'
                          ' · ${'stocktake.pending'.tr}: ${controller.pending.value}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: controller.search,
                    onChanged: controller.onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'stocktake.searchHint'.tr,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => SegmentTabs<StocktakeTab>(
                tabs: [
                  SegmentTab(
                    value: StocktakeTab.uncounted,
                    label:
                        '${'stocktake.tab.uncounted'.tr} (${controller.uncounted.length})',
                  ),
                  SegmentTab(
                    value: StocktakeTab.counted,
                    label:
                        '${'stocktake.tab.counted'.tr} (${controller.counted.length})',
                  ),
                  SegmentTab(
                    value: StocktakeTab.extras,
                    label:
                        '${'stocktake.tab.extras'.tr} (${controller.extras.length})',
                  ),
                ],
                selected: controller.tab.value,
                onChanged: controller.setTab,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Obx(() {
                if (controller.tab.value == StocktakeTab.extras) {
                  return _extrasList(context);
                }
                final list = controller.visible;
                if (list.isEmpty) {
                  return Center(child: Text('common.empty'.tr));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _itemTile(context, list[i]),
                );
              }),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Obx(
              () => FilledButton.icon(
                onPressed: controller.sending.value ? null : controller.send,
                icon: controller.sending.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  '${'stocktake.send'.tr} (${controller.pending.value})',
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _itemTile(BuildContext context, StocktakeLocalItem item) {
    final theme = Theme.of(context);
    final diff = _diff(item);
    return ListTile(
      leading: item.photoFileId == null
          ? null
          : FutureBuilder<String?>(
              future: controller.photoUrl(item.photoFileId!),
              builder: (_, snapshot) {
                final url = snapshot.data;
                if (url == null) {
                  return const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.image_outlined),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.network(
                    url,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                );
              },
            ),
      title: Text('${item.code} — ${item.name}'),
      subtitle: Text(
        [
          if (item.lotNo != null) '${'scan.lot.lotNo'.tr}: ${item.lotNo}',
          if (item.location != null) item.location!,
          '${'stocktake.bookQty'.tr}: ${item.bookQty}',
          if (item.counted)
            '${'stocktake.countedQty'.tr}: ${item.countedQty}'
                '${diff == null || diff == 0 ? '' : ' (${diff > 0 ? '+' : ''}$diff)'}',
          if (item.conflict) 'stocktake.conflict'.tr,
          if (item.counted && !item.synced && !item.conflict)
            'stocktake.unsent'.tr,
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: item.conflict
              ? context.status.warning
              : (diff != null && diff != 0)
              ? context.status.danger
              : null,
        ),
      ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _countSheet(context, item),
    );
  }

  Widget _extrasList(BuildContext context) {
    return Obx(() {
      if (controller.extras.isEmpty) {
        return Center(child: Text('common.empty'.tr));
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: controller.extras.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final e = controller.extras[i];
          return ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(e.code),
            subtitle: Text(
              '${'stocktake.countedQty'.tr}: ${e.qty}'
              '${e.synced ? ' · ${'stocktake.synced'.tr}' : ' · ${'stocktake.unsent'.tr}'}',
            ),
          );
        },
      );
    });
  }

  int? _diff(StocktakeLocalItem item) {
    final book = int.tryParse(item.bookQty.split('.').first);
    final counted = int.tryParse((item.countedQty ?? '').split('.').first);
    if (book == null || counted == null) return null;
    return counted - book;
  }

  Future<void> _scanContinuous(BuildContext context) async {
    final codes = await Get.toNamed<List<String>>(
      Routes.scan,
      arguments: {'continuous': true},
    );
    if (!context.mounted) return;
    if (codes == null || codes.isEmpty) return;
    for (final code in codes) {
      final item = controller.resolve(code);
      if (item == null) {
        final qty = TextEditingController(text: '1');
        final ok = await Get.dialog<bool>(
          AlertDialog(
            title: Text('stocktake.extraFound'.trParams({'code': code})),
            content: QtyField(
              controller: qty,
              label: 'stocktake.countedQty'.tr,
            ),
            actions: [
              TextButton(onPressed: Get.back, child: Text('common.cancel'.tr)),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: Text('common.add'.tr),
              ),
            ],
          ),
        );
        if (ok == true) {
          await controller.addExtra(
            code: code,
            qty: qty.text.trim().isEmpty ? '1' : qty.text.trim(),
          );
        }
        qty.dispose();
        continue;
      }
      if (item.counted) {
        final again = await Get.dialog<bool>(
          AlertDialog(
            title: Text('stocktake.recount'.tr),
            content: Text(
              '${item.code} — ${item.name}\n${'stocktake.countedQty'.tr}: ${item.countedQty}',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('common.no'.tr),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: Text('common.yes'.tr),
              ),
            ],
          ),
        );
        if (again != true) continue;
      }
      if (!context.mounted) return;
      await _countSheet(context, item);
    }
  }

  Future<void> _countSheet(
    BuildContext context,
    StocktakeLocalItem item,
  ) async {
    final isEquipment = item.equipmentId != null;
    final qty = TextEditingController(
      text: item.countedQty ?? (isEquipment ? '1' : item.bookQty),
    );
    var status = item.countedStatus ?? 'active';
    final location = TextEditingController(
      text: item.countedLocation ?? item.location ?? '',
    );
    final note = TextEditingController(text: item.note ?? '');
    final clientId = controller.createClientId();
    var photoFileId = item.photoFileId;
    var photoQueued = false;
    await Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom:
                MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${item.code} — ${item.name}',
                    style: Get.theme.textTheme.titleSmall,
                  ),
                  Text(
                    '${'stocktake.bookQty'.tr}: ${item.bookQty}'
                    '${item.lotNo == null ? '' : ' · ${'scan.lot.lotNo'.tr}: ${item.lotNo}'}',
                    style: Get.theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  QtyField(
                    controller: qty,
                    label: isEquipment
                        ? 'stocktake.presentQty'.tr
                        : 'stocktake.countedQty'.tr,
                  ),
                  if (isEquipment) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        for (final s in ['active', 'broken', 'suspended'])
                          ChoiceChip(
                            label: Text('status.$s'.tr),
                            selected: status == s,
                            onSelected: (v) {
                              if (v) setState(() => status = s);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: location,
                      decoration: InputDecoration(
                        labelText: 'stocktake.location'.tr,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: note,
                    decoration: InputDecoration(
                      labelText: 'repairs.logs.note'.tr,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final upload = await controller.attachPhoto(
                        item,
                        clientId: clientId,
                      );
                      if (upload == null) return;
                      setState(() {
                        final fileId = upload.attachment?.fileId;
                        if (fileId != null) photoFileId = fileId;
                        if (upload.status == AttachmentUploadStatus.queued) {
                          photoQueued = true;
                        }
                      });
                    },
                    icon: Icon(
                      photoFileId != null || photoQueued
                          ? Icons.check_circle_outline
                          : Icons.camera_alt_outlined,
                    ),
                    label: Text(
                      photoFileId != null
                          ? 'stocktake.photo.attached'.tr
                          : photoQueued
                          ? 'stocktake.photo.queued'.tr
                          : 'stocktake.photo.add'.tr,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () async {
                      await controller.saveCount(
                        item,
                        qty: qty.text.trim().isEmpty
                            ? (isEquipment ? '1' : item.bookQty)
                            : qty.text.trim(),
                        status: isEquipment ? status : null,
                        location: isEquipment ? location.text.trim() : null,
                        note: note.text.trim().isEmpty
                            ? null
                            : note.text.trim(),
                        photoFileId: photoFileId,
                        clientId: clientId,
                      );
                      Get.back();
                    },
                    child: Text('common.save'.tr),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Get.theme.colorScheme.surface,
    );
    qty.dispose();
    location.dispose();
    note.dispose();
  }
}
