import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StatusTone { success, warning, danger, info, muted }

({Color color, Color background, Color foreground}) paletteForTone(
  BuildContext context,
  StatusTone tone,
) {
  final s = context.status;
  return switch (tone) {
    StatusTone.success => (
      color: s.success,
      background: s.successBackground,
      foreground: s.successForeground,
    ),
    StatusTone.warning => (
      color: s.warning,
      background: s.warningBackground,
      foreground: s.warningForeground,
    ),
    StatusTone.danger => (
      color: s.danger,
      background: s.dangerBackground,
      foreground: s.dangerForeground,
    ),
    StatusTone.info => (
      color: s.info,
      background: s.infoBackground,
      foreground: s.infoForeground,
    ),
    StatusTone.muted => (
      color: s.muted,
      background: s.mutedBackground,
      foreground: s.mutedForeground,
    ),
  };
}

/// Map tình trạng máy (EquipmentStatusDto.status) → tone.
StatusTone toneForEquipmentStatus(String status) => switch (status) {
  'active' => StatusTone.success,
  'broken' => StatusTone.danger,
  'awaiting_parts' => StatusTone.warning,
  _ => StatusTone.muted,
};

/// Map trạng thái phiếu sửa chữa → tone.
StatusTone toneForRepairStatus(String status) => switch (status) {
  'new' => StatusTone.muted,
  'accepted' || 'in_progress' => StatusTone.info,
  'awaiting_parts' || 'awaiting_vendor' => StatusTone.warning,
  'completed' || 'acceptance' => StatusTone.success,
  'cancelled' => StatusTone.danger,
  _ => StatusTone.muted,
};

/// Map mức khẩn → tone.
StatusTone toneForRepairSeverity(String severity) => switch (severity) {
  'critical' || 'high' => StatusTone.danger,
  'medium' => StatusTone.warning,
  _ => StatusTone.info,
};

/// Map trạng thái công việc bảo dưỡng → tone.
StatusTone toneForTaskStatus(String status) => switch (status) {
  'scheduled' => StatusTone.info,
  'in_progress' => StatusTone.warning,
  'done' => StatusTone.success,
  'skipped' => StatusTone.muted,
  'overdue' => StatusTone.danger,
  _ => StatusTone.muted,
};

/// Map trạng thái phiếu yêu cầu → tone.
StatusTone toneForRequestStatus(String status) => switch (status) {
  'draft' => StatusTone.muted,
  'submitted' || 'dept_approved' => StatusTone.info,
  'approved' || 'partially_approved' => StatusTone.success,
  'rejected' || 'cancelled' => StatusTone.danger,
  'issued' || 'received' || 'converted' => StatusTone.success,
  _ => StatusTone.muted,
};

/// Map trạng thái kỳ dự trù → tone.
StatusTone toneForDemandPeriodStatus(String status) => switch (status) {
  'draft' => StatusTone.muted,
  'collecting' => StatusTone.info,
  'consolidating' => StatusTone.warning,
  'approved' => StatusTone.success,
  'closed' => StatusTone.success,
  'cancelled' => StatusTone.danger,
  _ => StatusTone.muted,
};

/// Map trạng thái phiếu dự trù khoa → tone.
StatusTone toneForDemandRequestStatus(String status) => switch (status) {
  'draft' => StatusTone.muted,
  'submitted' => StatusTone.warning,
  'dept_approved' => StatusTone.info,
  'returned' => StatusTone.danger,
  'accepted' => StatusTone.success,
  _ => StatusTone.muted,
};

/// Map quyết định dòng tổng hợp → tone.
StatusTone toneForDemandDecision(String decision) => switch (decision) {
  'buy' => StatusTone.info,
  'from_stock' => StatusTone.success,
  'reject' => StatusTone.danger,
  _ => StatusTone.muted,
};

/// Badge trạng thái cao 24px, dùng dot để không chỉ dựa vào màu chữ.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.tone, required this.label});

  final StatusTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForTone(context, tone);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: palette.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.appText.caption.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
