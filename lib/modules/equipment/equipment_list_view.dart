import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/icon_chip.dart';
import '../../core/widgets/large_title_scaffold.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/segment_tabs.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/equipment.dart';
import 'equipment_list_controller.dart';

/// Danh sách máy `/equipment`: tìm + segment trạng thái + lọc khoa/phòng.
class EquipmentListView extends GetView<EquipmentListController> {
  const EquipmentListView({super.key});

  @override
  Widget build(BuildContext context) {
    return LargeTitleScaffold(
      title: 'equipment.list.title'.tr,
      floatingActionButton: GradientFab(
        label: 'equipment.list.add'.tr,
        icon: LucideIcons.plus,
        onPressed: () async {
          await Get.toNamed(Routes.equipmentNew);
          await controller.load();
        },
      ),
      header: Column(
        children: [
          TextField(
            controller: controller.searchController,
            onChanged: controller.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              hintText: 'equipment.list.search'.tr,
              filled: true,
              fillColor: context.isDark ? AppColors.mutedDark : AppColors.muted,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              border: _searchBorder,
              enabledBorder: _searchBorder,
              focusedBorder: _searchBorder,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => SegmentTabs<String>(
              tabs: [
                SegmentTab(value: '', label: 'equipment.list.status.all'.tr),
                SegmentTab(value: 'active', label: 'status.active'.tr),
                SegmentTab(value: 'broken', label: 'status.broken'.tr),
                SegmentTab(
                  value: 'awaiting_parts',
                  label: 'status.awaiting_parts'.tr,
                ),
                SegmentTab(value: 'suspended', label: 'status.suspended'.tr),
              ],
              selected: controller.status.value,
              onChanged: controller.setStatus,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: 'equipment.list.filterDepartment'.tr,
                    value: controller.department.value?.name,
                    onTap: () => controller.pickDepartment(context),
                    onClear: controller.clearDepartment,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FilterChip(
                    label: 'equipment.list.filterRoom'.tr,
                    value: controller.room.value?.name,
                    onTap: () => controller.pickRoom(context),
                    onClear: controller.clearRoom,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.items.isEmpty) {
          return const LoadingList();
        }
        if (controller.error.value != null && controller.items.isEmpty) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.items.isEmpty) {
          return EmptyState(
            icon: LucideIcons.microscope,
            title: 'equipment.list.empty'.tr,
            action: OutlinedButton(
              onPressed: controller.clearFilters,
              child: Text('equipment.list.clearFilters'.tr),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 400) {
                unawaited(controller.loadMore());
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl * 3,
              ),
              itemCount: controller.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final item = controller.items[i];
                return _EquipmentCard(
                  item: item,
                  onTap: () async {
                    await Get.toNamed(Routes.equipment(item.id));
                    await controller.load();
                  },
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

const _searchBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
  borderSide: BorderSide.none,
);

/// Chip lọc: chưa chọn = viền mờ + ▾; đã chọn = nền primary-soft + × để bỏ.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = value != null && value!.isNotEmpty;
    return Material(
      color: active ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: active ? Colors.transparent : context.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  active ? value! : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appText.label.copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (active)
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(999),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: scheme.onPrimaryContainer,
                  ),
                )
              else
                Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.item, required this.onTap});

  final EquipmentSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final codeModel = [
      item.code,
      item.model,
    ].where((e) => e != null && e.trim().isNotEmpty).join(' · ');
    final place = [
      item.departmentLabel,
      item.room?.name,
      item.location,
    ].where((e) => e != null && e.trim().isNotEmpty).join(' · ');
    return ListItemCard(
      leading: IconChip(icon: _groupIcon(item.groupLabel)),
      title: item.name,
      badge: StatusBadge(
        tone: toneForEquipmentStatus(item.status),
        label: 'status.${item.status}'.tr,
      ),
      metas: [
        if (codeModel.isNotEmpty) ListMeta(LucideIcons.hash, codeModel),
        if (place.isNotEmpty) ListMeta(LucideIcons.mapPin, place),
      ],
      onTap: onTap,
    );
  }
}

/// Icon chip theo nhóm máy (đoán theo tên nhóm).
IconData _groupIcon(String? group) {
  final g = (group ?? '').toLowerCase();
  if (g.contains('x-quang') || g.contains('xquang') || g.contains('ct')) {
    return LucideIcons.scanLine;
  }
  if (g.contains('siêu âm') || g.contains('sieu am')) {
    return LucideIcons.activity;
  }
  if (g.contains('xét nghiệm') ||
      g.contains('huyết') ||
      g.contains('sinh hoá') ||
      g.contains('vi sinh')) {
    return LucideIcons.flaskConical;
  }
  if (g.contains('hồi sức') ||
      g.contains('thở') ||
      g.contains('monitor') ||
      g.contains('tim')) {
    return LucideIcons.heartPulse;
  }
  if (g.contains('cntt') || g.contains('máy tính') || g.contains('server')) {
    return LucideIcons.monitorCog;
  }
  return LucideIcons.microscope;
}
