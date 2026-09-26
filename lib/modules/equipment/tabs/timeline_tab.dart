import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/timeline_list.dart';
import '../../../data/models/equipment_extras.dart';
import '../../../data/repositories/equipment_repository.dart';

/// Tab "Timeline": sự kiện phân trang + thêm ghi chú.
class TimelineTabController extends GetxController {
  TimelineTabController({required this.equipment, required this.id});

  final EquipmentRepository equipment;
  final String id;

  final RxList<EquipmentEvent> items = <EquipmentEvent>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
  final RxBool loadingMore = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    _page = 1;
    try {
      final page = await equipment.events(id, page: _page, limit: 20);
      items.assignAll(page.items);
      total.value = page.total.toInt();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loadingMore.value || items.length >= total.value) return;
    loadingMore.value = true;
    try {
      final page = await equipment.events(id, page: _page + 1, limit: 20);
      _page += 1;
      items.addAll(page.items);
      total.value = page.total.toInt();
    } catch (e) {
      AppSnackbar.error(e);
    } finally {
      loadingMore.value = false;
    }
  }

  Future<void> addNote(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await equipment.addNote(id, text.trim());
      AppSnackbar.success('equipment.note.saved'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }
}

class TimelineTab extends GetView<TimelineTabController> {
  const TimelineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.loading.value) return const LoadingList();
        if (controller.error.value != null) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.items.isEmpty) {
          return EmptyState(
            icon: LucideIcons.history,
            title: 'common.empty'.tr,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TimelineList(
                items: [
                  for (final e in controller.items)
                    TimelineEntry(
                      title: e.title,
                      at: e.at,
                      summary: e.summary,
                      by: e.byUserId,
                      icon: _iconFor(e.type),
                    ),
                ],
              ),
              if (controller.items.length < controller.total.value)
                Obx(
                  () => AppButton.soft(
                    tone: AppButtonTone.primary,
                    label: 'common.loadMore'.tr,
                    loading: controller.loadingMore.value,
                    onPressed: controller.loadMore,
                  ),
                ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addNote',
        tooltip: 'equipment.timeline.addNote'.tr,
        onPressed: () => _addNote(context, controller),
        child: const Icon(LucideIcons.notebookPen),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
    'status' => LucideIcons.refreshCw,
    'maintenance' => LucideIcons.wrench,
    'repair' => LucideIcons.wrench,
    'transfer' => LucideIcons.arrowRightLeft,
    'counter' => LucideIcons.gauge,
    _ => LucideIcons.circle,
  };
}

Future<void> _addNote(BuildContext context, TimelineTabController c) async {
  final v = await AppDialog.prompt(
    context,
    title: 'equipment.note.title'.tr,
    label: 'equipment.note.hint'.tr,
    maxLines: 3,
  );
  if (v == null || v.isEmpty) return;
  await c.addNote(v);
}
