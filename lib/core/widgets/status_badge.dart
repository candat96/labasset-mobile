import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StatusTone { success, warning, danger, info, muted }

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

/// Badge trạng thái: màu + icon (không chỉ dựa vào màu).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.tone, required this.label});

  final StatusTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = context.status;
    final (color, icon) = switch (tone) {
      StatusTone.success => (s.success, Icons.check_circle_outline),
      StatusTone.warning => (s.warning, Icons.warning_amber_outlined),
      StatusTone.danger => (s.danger, Icons.cancel_outlined),
      StatusTone.info => (s.info, Icons.info_outline),
      StatusTone.muted => (s.muted, Icons.circle_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
