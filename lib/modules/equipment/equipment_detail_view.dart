import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/equipment.dart';
import 'equipment_detail_controller.dart';

/// Thẻ tóm tắt hồ sơ máy — màn mẫu cho pattern repository → controller → view.
class EquipmentDetailView extends GetView<EquipmentDetailController> {
  const EquipmentDetailView({super.key});

  @override
  String? get tag => Get.parameters['id'];

  static const _quickActions = [
    (key: 'reportFault', icon: Icons.report_problem_outlined),
    (key: 'adhocMaintenance', icon: Icons.build_circle_outlined),
    (key: 'issueSupplies', icon: Icons.outbox_outlined),
    (key: 'counters', icon: Icons.speed_outlined),
    (key: 'updateStatus', icon: Icons.sync_alt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('equipment.title'.tr)),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final err = controller.error.value;
        if (err != null) {
          if (ApiError.from(err).status == 404) {
            return EmptyState(
              icon: Icons.search_off,
              title: 'equipment.notFound'.tr,
            );
          }
          return ErrorState(error: err, onRetry: controller.load);
        }
        final e = controller.item.value!;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _SummaryCard(e: e),
              const SizedBox(height: AppSpacing.md),
              _DueCard(e: e),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'equipment.quickActions'.tr,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final a in _quickActions)
                    ActionChip(
                      avatar: Icon(a.icon, size: 18),
                      label: Text('placeholder.${a.key}'.tr),
                      onPressed: () =>
                          Get.toNamed(Routes.placeholderFor(a.key)),
                    ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.e});
  final EquipmentSummary e;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(String, String?)>[
      ('equipment.code'.tr, e.code),
      ('equipment.model'.tr, e.model),
      ('equipment.serial'.tr, e.serial),
      (
        'equipment.department'.tr,
        [e.departmentLabel, e.location].whereType<String>().join(' · '),
      ),
      ('equipment.group'.tr, e.groupLabel),
      ('equipment.manufacturer'.tr, e.manufacturerLabel),
      ('equipment.staff'.tr, e.staffInCharge?.fullName),
      ('equipment.warranty'.tr, formatDate(e.warrantyUntil)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            StatusBadge(
              tone: toneForEquipmentStatus(e.status),
              label: 'status.${e.status}'.tr,
            ),
            const Divider(height: AppSpacing.xl),
            for (final (k, v) in rows)
              if (v != null && v.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(k, style: theme.textTheme.bodySmall),
                      ),
                      Expanded(
                        child: Text(v, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.e});
  final EquipmentSummary e;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    Widget row(String label, String? iso, {bool forceOverdue = false}) {
      final d = iso == null ? null : DateTime.tryParse(iso);
      final overdue = forceOverdue || (d != null && d.isBefore(now));
      final color = overdue
          ? context.status.danger
          : theme.colorScheme.onSurface;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              overdue ? Icons.warning_amber_outlined : Icons.event_outlined,
              size: 18,
              color: overdue
                  ? context.status.danger
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              d == null ? '—' : formatDate(d),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (overdue) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                'equipment.overdue'.tr,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: context.status.danger,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          children: [
            row('equipment.nextMaintenance'.tr, e.nextMaintenanceAt),
            row(
              'equipment.nextCalibration'.tr,
              e.nextCalibrationAt,
              forceOverdue: e.calibrationOverdue,
            ),
          ],
        ),
      ),
    );
  }
}
