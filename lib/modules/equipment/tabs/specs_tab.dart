import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/format.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/equipment_detail.dart';

/// Tab "Thông số": specs + thông tin chung dạng key-value.
class SpecsTab extends StatelessWidget {
  const SpecsTab({super.key, required this.e});

  final EquipmentDetail e;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final specs = e.specs;
    final env = specs?.env;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionCard(
          title: 'equipment.info.title'.tr,
          child: Column(
            children: [
              _row(context, 'equipment.code'.tr, e.code),
              _row(context, 'equipment.model'.tr, e.model),
              _row(context, 'equipment.serial'.tr, e.serial),
              _row(context, 'equipment.assetCode'.tr, e.assetCode),
              _row(context, 'equipment.countryOfOrigin'.tr, e.countryOfOrigin),
              _row(
                context,
                'equipment.manufactureYear'.tr,
                e.manufactureYear?.toString(),
              ),
              _row(context, 'equipment.circulationNo'.tr, e.circulationNo),
              _row(
                context,
                'equipment.purchaseContractNo'.tr,
                e.purchaseContractNo,
              ),
              _row(context, 'equipment.decisionNo'.tr, e.decisionNo),
              _row(context, 'equipment.group'.tr, e.group?.name),
              _row(context, 'equipment.manufacturer'.tr, e.manufacturer?.name),
              _linkedRow(
                context,
                'equipment.department'.tr,
                e.department?.name,
                onTap: e.department == null
                    ? null
                    : () => Get.toNamed(
                        Routes.equipmentList,
                        parameters: {'departmentId': e.department!.id},
                      ),
              ),
              _linkedRow(
                context,
                'equipment.room.name'.tr,
                e.room?.name,
                onTap: e.room == null
                    ? null
                    : () => Get.toNamed(
                        Routes.equipmentList,
                        arguments: {'room': e.room},
                      ),
              ),
              _row(context, 'equipment.location.label'.tr, e.location),
              _row(context, 'equipment.staff'.tr, e.staffInCharge?.fullName),
              _row(
                context,
                'equipment.warranty'.tr,
                formatDate(e.warrantyUntil),
              ),
              _row(
                context,
                'equipment.nextMaintenance'.tr,
                formatDateTime(e.nextMaintenanceAt),
              ),
              _row(
                context,
                'equipment.nextCalibration'.tr,
                formatDateTime(e.nextCalibrationAt),
              ),
              _row(
                context,
                'equipment.counters.runHours'.tr,
                e.currentRunHours,
              ),
              _row(
                context,
                'equipment.counters.testCount'.tr,
                e.currentTestCount?.toString(),
              ),
              _row(context, 'equipment.notes'.tr, e.notes),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'equipment.tab.specs'.tr,
          child: Column(
            children: [
              _row(context, 'equipment.specs.voltage'.tr, specs?.voltage),
              _row(context, 'equipment.specs.power'.tr, specs?.power),
              _row(context, 'equipment.specs.dimensions'.tr, specs?.dimensions),
              _row(context, 'equipment.specs.weight'.tr, specs?.weight),
              _row(context, 'equipment.specs.env.temp'.tr, env?.temp),
              _row(context, 'equipment.specs.env.humidity'.tr, env?.humidity),
              _row(context, 'equipment.specs.env.ups'.tr, env?.ups),
              _row(context, 'equipment.specs.env.water'.tr, env?.water),
              _row(context, 'equipment.specs.env.gas'.tr, env?.gas),
            ],
          ),
        ),
        if (e.statusNote != null && e.statusNote!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'equipment.status.reason'.tr,
            child: Text(e.statusNote!, style: theme.textTheme.bodyMedium),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  /// Dòng bấm được: mở danh sách máy theo khoa/phòng của giá trị đó.
  Widget _linkedRow(
    BuildContext context,
    String label,
    String? value, {
    required VoidCallback? onTap,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onTap == null ? null : theme.colorScheme.primary,
            ),
          ),
        ),
        if (onTap != null)
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.primary,
          ),
      ],
    );
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }
}
