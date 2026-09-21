import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/format.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/list_item_card.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/repair.dart';
import '../../../data/repositories/repairs_repository.dart';

/// Tab "Sửa chữa" trong hồ sơ máy: lịch sử phiếu sửa chữa của máy.
class EquipmentRepairsTabController extends GetxController {
  EquipmentRepairsTabController({
    required this.repairs,
    required this.equipmentId,
  });

  final RepairsRepository repairs;
  final String equipmentId;

  final RxList<RepairSummary> items = <RepairSummary>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final page = await repairs.list(equipmentId: equipmentId, limit: 50);
      items.assignAll(page.items);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }
}

class RepairsTab extends GetView<EquipmentRepairsTabController> {
  const RepairsTab({super.key});

  Future<void> _report() async {
    final id =
        (await Get.toNamed(
              '${Routes.repairNew}?equipmentId=${controller.equipmentId}',
            ))
            as String?;
    if (id != null) await Get.toNamed(Routes.repair(id));
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value && controller.items.isEmpty) {
        return const LoadingList();
      }
      if (controller.error.value != null && controller.items.isEmpty) {
        return ErrorState(
          error: controller.error.value!,
          onRetry: controller.load,
        );
      }
      final header = Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: GradientButton(
          label: 'equipment.repairs.report'.tr,
          icon: LucideIcons.triangleAlert,
          onPressed: _report,
        ),
      );
      if (controller.items.isEmpty) {
        return Column(
          children: [
            header,
            Expanded(
              child: EmptyState(
                icon: LucideIcons.wrench,
                title: 'equipment.repairs.empty'.tr,
              ),
            ),
          ],
        );
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxl),
          itemCount: controller.items.length + 1,
          separatorBuilder: (_, i) =>
              SizedBox(height: i == 0 ? 0 : AppSpacing.md),
          itemBuilder: (_, i) {
            if (i == 0) return header;
            final r = controller.items[i - 1];
            final overdue =
                r.isOverdue ||
                (r.dueAt != null &&
                    (DateTime.tryParse(r.dueAt!)?.isBefore(DateTime.now()) ??
                        false));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ListItemCard(
                code: r.code,
                badge: StatusBadge(
                  tone: toneForRepairStatus(r.status),
                  label: 'status.repair.${r.status}'.tr,
                ),
                title: r.description.isEmpty ? r.code : r.description,
                accentColor: paletteForTone(
                  context,
                  toneForRepairSeverity(r.severity),
                ).color,
                metas: [
                  ListMeta(
                    LucideIcons.userRound,
                    r.assigneeId == null
                        ? 'repairs.assignee.none'.tr
                        : 'equipment.staff'.tr,
                  ),
                  if (r.createdAt != null)
                    ListMeta(LucideIcons.calendarDays, formatDate(r.createdAt)),
                  if (r.dueAt != null)
                    ListMeta(
                      overdue ? LucideIcons.clockAlert : LucideIcons.clock3,
                      formatSla(r.dueAt),
                      color: overdue ? context.status.danger : null,
                    ),
                ],
                onTap: () async {
                  await Get.toNamed(Routes.repair(r.id));
                  await controller.load();
                },
              ),
            );
          },
        ),
      );
    });
  }
}
