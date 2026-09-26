import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/icon_chip.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/large_title_scaffold.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/segment_tabs.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/kpi.dart';
import 'kpi_controller.dart';

/// "Hiệu suất của tôi": điểm tổng + huy hiệu hạng, ba thanh điểm mảng, bốn
/// chỉ số mảng đang chọn, biểu đồ 6 kỳ, danh sách việc hoàn tất (bấm mở phiếu).
/// Quản trị viện thêm tab **Toàn viện** (chỉ đọc, không chốt kỳ).
class KpiView extends GetView<KpiController> {
  const KpiView({super.key});

  static const _types = ['week', 'month', 'quarter', 'year'];

  @override
  Widget build(BuildContext context) {
    return LargeTitleScaffold(
      title: 'kpi.title'.tr,
      header: Column(
        children: [
          Obx(
            () => SegmentTabs<String>(
              tabs: [
                for (final t in _types)
                  SegmentTab(value: t, label: 'kpi.period.$t'.tr),
              ],
              selected: controller.periodType.value,
              onChanged: controller.setPeriodType,
            ),
          ),
          if (controller.tabs.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Obx(
              () => SegmentTabs<KpiTab>(
                tabs: [
                  for (final t in controller.tabs)
                    SegmentTab(value: t, label: 'kpi.tab.${t.name}'.tr),
                ],
                selected: controller.tab.value,
                onChanged: controller.setTab,
              ),
            ),
          ],
        ],
      ),
      body: Obx(() {
        if (controller.loading.value &&
            controller.score.value == null &&
            controller.board.value == null) {
          return const LoadingList();
        }
        final err = controller.error.value;
        if (err != null) {
          return ErrorState(error: err, onRetry: controller.load);
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: controller.tab.value == KpiTab.hospital
              ? _HospitalTab(controller: controller)
              : _MineTab(controller: controller),
        );
      }),
    );
  }
}

class _MineTab extends StatelessWidget {
  const _MineTab({required this.controller});
  final KpiController controller;

  @override
  Widget build(BuildContext context) {
    final person = controller.score.value;
    if (person == null) {
      return EmptyState(icon: LucideIcons.gauge, title: 'kpi.noData'.tr);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl * 2,
      ),
      children: [
        _ScoreCard(person: person, showRank: controller.showRank),
        const SizedBox(height: AppSpacing.md),
        if (person.items == 0)
          SectionCard(
            child: EmptyState(icon: LucideIcons.gauge, title: 'kpi.noData'.tr),
          )
        else ...[
          SectionCard(
            title: 'kpi.areas'.tr,
            child: _AreaBars(controller: controller),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'kpi.metrics'.tr,
            child: _MetricBars(controller: controller),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'kpi.history'.tr,
            child: _HistoryChart(
              points: controller.history.toList(),
              type: controller.periodType.value,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'kpi.tasks'.tr,
            child: _TaskList(controller: controller),
          ),
        ],
      ],
    );
  }
}

/// Thẻ điểm tổng lớn + huy hiệu hạng (ẩn khi API không trả hạng).
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.person, required this.showRank});
  final KpiPerson person;
  final bool showRank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = person.total;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('kpi.total'.tr, style: context.appText.section),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          total == null ? '—' : formatNumber(total, digits: 1),
                          style: context.appText.kpi.copyWith(
                            fontSize: 40,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text('/ 100', style: context.appText.caption),
                      ],
                    ),
                  ],
                ),
              ),
              if (showRank)
                _RankBadge(rank: person.rank!)
              else
                const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                '${formatNumber(person.credits, digits: 1)} '
                '${'kpi.credits'.tr} · ${person.items} ${'kpi.items'.tr}',
                style: context.appText.label,
              ),
              if (person.inactive)
                StatusBadge(tone: StatusTone.muted, label: 'kpi.inactive'.tr),
              if (person.insufficient)
                StatusBadge(
                  tone: StatusTone.warning,
                  label: 'kpi.insufficient'.tr,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${'kpi.period.${person.type}'.tr} · '
            '${formatDate(person.start)} – ${formatDate(person.end)}',
            style: context.appText.caption,
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final num rank;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    final top3 = rank <= 3;
    final color = top3 ? status.warning : status.info;
    final background = top3 ? status.warningBackground : status.infoBackground;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.trophy, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'kpi.rankBadge'.trParams({'rank': '${rank.toInt()}'}),
            style: context.appText.label.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ba thanh điểm mảng; bấm để chọn mảng xem bốn chỉ số bên dưới.
class _AreaBars extends StatelessWidget {
  const _AreaBars({required this.controller});
  final KpiController controller;

  @override
  Widget build(BuildContext context) {
    final person = controller.score.value!;
    return Column(
      children: [
        for (final name in KpiController.areas)
          _ScoreBar(
            label: 'kpi.area.$name'.tr,
            value: person.areas.area(name)?.score,
            selected: controller.area.value == name,
            onTap: () => controller.setArea(name),
          ),
      ],
    );
  }
}

/// Bốn chỉ số của mảng đang chọn (kiểm định không có tốc độ).
class _MetricBars extends StatelessWidget {
  const _MetricBars({required this.controller});
  final KpiController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.metricRows;
    if (rows.isEmpty) {
      return Text('common.empty'.tr, style: context.appText.caption);
    }
    return Column(
      children: [
        for (final m in rows)
          _ScoreBar(label: 'kpi.metric.${m.key}'.tr, value: m.value),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.value,
    this.selected = false,
    this.onTap,
  });
  final String label;
  final num? value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = value == null
        ? 0.0
        : (value! / 100).clamp(0.0, 1.0).toDouble();
    final bar = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.appText.label.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? scheme.primary : null,
                  ),
                ),
              ),
              Text(
                value == null ? '—' : formatNumber(value, digits: 0),
                style: context.appText.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: context.isDark
                  ? AppColors.segmentDark
                  : AppColors.segment,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return bar;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: onTap,
      child: bar,
    );
  }
}

/// Biểu đồ cột điểm tổng 6 kỳ gần nhất.
class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.points, required this.type});
  final List<KpiPoint> points;
  final String type;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Text('common.empty'.tr, style: context.appText.caption);
    }
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in points)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    p.total == null ? '' : formatNumber(p.total, digits: 0),
                    style: context.appText.caption,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 20,
                    height:
                        4 +
                        (p.total == null
                            ? 0.0
                            : (p.total! / 100).clamp(0.0, 1.0).toDouble() * 90),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _periodLabel(p.start, type),
                    style: context.appText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _periodLabel(String start, String type) {
  final parts = start.split('-');
  if (parts.length < 2) return start;
  final month = int.tryParse(parts[1]) ?? 1;
  return switch (type) {
    'year' => parts[0],
    'quarter' => 'Q${(month - 1) ~/ 3 + 1}',
    'week' => '${parts[2]}/${parts[1]}',
    _ => 'T$month',
  };
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.controller});
  final KpiController controller;

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasks;
    if (tasks.isEmpty) {
      return Text('kpi.noTasks'.tr, style: context.appText.caption);
    }
    return Column(
      children: [
        for (final item in tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListItemCard(
              code: item.code,
              title: item.equipmentName ?? item.title,
              badge: StatusBadge(
                tone: item.onTime ? StatusTone.success : StatusTone.danger,
                label: item.onTime ? 'kpi.onTime'.tr : 'kpi.late'.tr,
              ),
              leading: IconChip(
                icon: _areaIcon(item.area),
                tone: StatusTone.info,
              ),
              metas: [
                ListMeta(LucideIcons.layers, 'kpi.area.${item.area}'.tr),
                if (item.departmentName != null)
                  ListMeta(LucideIcons.building2, item.departmentName!),
                ListMeta(
                  LucideIcons.calendarCheck,
                  formatDate(item.completedAt),
                ),
                if (item.quality != null)
                  ListMeta(
                    LucideIcons.star,
                    '${formatNumber(item.quality, digits: 0)}/100',
                  ),
              ],
              onTap: () => controller.openTask(item),
            ),
          ),
      ],
    );
  }
}

IconData _areaIcon(String area) => switch (area) {
  'repair' => LucideIcons.wrench,
  'maintenance' => LucideIcons.calendarCheck,
  'calibration' => LucideIcons.badgeCheck,
  _ => LucideIcons.circleDot,
};

/// Tab Toàn viện (chỉ ADM): bốn thẻ tổng + bảng xếp hạng rút gọn, chỉ đọc.
class _HospitalTab extends StatelessWidget {
  const _HospitalTab({required this.controller});
  final KpiController controller;

  @override
  Widget build(BuildContext context) {
    final totals = controller.totals.value ?? const KpiTotals();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl * 2,
      ),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.5,
          children: [
            KpiTile(
              label: 'kpi.totals.items'.tr,
              value: formatNumber(totals.items),
              icon: LucideIcons.listChecks,
              tone: StatusTone.info,
            ),
            KpiTile(
              label: 'kpi.totals.onTime'.tr,
              value: _percent(totals.onTime),
              icon: LucideIcons.clock,
              tone: StatusTone.success,
            ),
            KpiTile(
              label: 'kpi.totals.avgHandleHours'.tr,
              value: _hours(totals.avgHandleHours),
              icon: LucideIcons.timer,
              tone: StatusTone.warning,
            ),
            KpiTile(
              label: 'kpi.totals.avgQuality'.tr,
              value: _percent(totals.avgQuality),
              icon: LucideIcons.star,
              tone: StatusTone.info,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'kpi.ranking'.tr,
          child: Column(
            children: [
              for (final row in controller.staff)
                _RankRow(row: row, onTap: () => _openUser(context, row)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openUser(BuildContext context, KpiStaffRow row) async {
    final person = await controller.loadUser(row.userId);
    if (!context.mounted) return;
    await AppSheet.show<void>(
      context,
      builder: (_) => _UserDetailSheet(person: person),
    );
  }

  static String _percent(num? value) =>
      value == null ? '—' : '${formatNumber(value, digits: 1)}%';

  static String _hours(num? value) =>
      value == null ? '—' : formatNumber(value, digits: 1);
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.row, this.onTap});
  final KpiStaffRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.status.mutedForeground;
    final rank = row.rank;
    final leading = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rank != null && rank <= 3
            ? context.status.warningBackground
            : scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        rank == null ? '–' : '$rank',
        style: context.appText.label.copyWith(
          fontWeight: FontWeight.w700,
          color: rank != null && rank <= 3
              ? context.status.warning
              : scheme.onSurfaceVariant,
        ),
      ),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          row.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.appText.bodyStrong.copyWith(
                            color: row.insufficient ? muted : null,
                          ),
                        ),
                      ),
                      if (row.inactive) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text('kpi.inactive'.tr, style: context.appText.caption),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.insufficient
                        ? 'kpi.insufficient'.tr
                        : '${formatNumber(row.credits, digits: 1)} '
                              '${'kpi.credits'.tr} · ${row.items} '
                              '${'kpi.items'.tr}',
                    style: context.appText.caption.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              row.total == null ? '—' : formatNumber(row.total, digits: 1),
              style: context.appText.kpi.copyWith(
                fontSize: 18,
                color: row.insufficient ? muted : scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chi tiết một người trong tab Toàn viện (chỉ đọc).
class _UserDetailSheet extends StatelessWidget {
  const _UserDetailSheet({required this.person});
  final KpiPerson person;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: person.fullName),
          const SizedBox(height: AppSpacing.md),
          _ScoreCard(person: person, showRank: person.rank != null),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'kpi.areas'.tr,
            child: Column(
              children: [
                for (final name in KpiController.areas)
                  _ScoreBar(
                    label: 'kpi.area.$name'.tr,
                    value: person.areas.area(name)?.score,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'kpi.tasks'.tr,
            child: Column(
              children: [
                for (final item
                    in (person.tasks?.items ?? const <KpiTaskItem>[]))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: IconChip(icon: _areaIcon(item.area)),
                    title: Text('${item.code} · ${item.title}'),
                    subtitle: Text(
                      [
                        'kpi.area.${item.area}'.tr,
                        if (item.departmentName != null) item.departmentName!,
                        formatDate(item.completedAt),
                      ].join(' · '),
                    ),
                  ),
                if ((person.tasks?.items ?? const []).isEmpty)
                  Text('kpi.noTasks'.tr, style: context.appText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
