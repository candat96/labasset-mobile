import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/room.dart';
import 'rooms_controller.dart';

/// Danh sách phòng nhóm theo khoa/phòng ban, kèm **tổng số máy** mỗi phòng —
/// dùng cho mode "Theo phòng" ở trang hồ sơ thiết bị.
class RoomsList extends StatelessWidget {
  const RoomsList({super.key, required this.controller, required this.onOpen});

  final RoomsController controller;

  /// Bấm một phòng → xem danh sách máy của phòng đó.
  final void Function(RoomRef room) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.loading.value && controller.rooms.isEmpty) {
        return const LoadingList();
      }
      if (controller.error.value != null && controller.rooms.isEmpty) {
        return ErrorState(
          error: controller.error.value!,
          onRetry: controller.load,
        );
      }
      if (controller.rooms.isEmpty) {
        return EmptyState(icon: LucideIcons.doorOpen, title: 'rooms.empty'.tr);
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxl * 3,
        ),
        children: [
          for (final group in controller.groups) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(group.title, style: theme.textTheme.labelLarge),
            ),
            for (final room in group.rooms) ...[
              ListItemCard(
                title: room.name,
                code: room.code,
                badge: _countBadge(controller.roomCounts[room.code]),
                metas: [
                  if (room.placeText case final place?)
                    ListMeta(LucideIcons.building2, place),
                  if (room.departmentCode case final code?)
                    ListMeta(LucideIcons.building, code),
                ],
                onTap: () => onOpen(room),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      );
    });
  }

  /// Badge "N máy" (chưa có số liệu thì không hiện).
  Widget? _countBadge(int? count) => count == null
      ? null
      : StatusBadge(
          tone: StatusTone.muted,
          label: 'rooms.machines'.trParams({'n': '$count'}),
        );
}
