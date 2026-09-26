import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Trạng thái rỗng: icon 40 trong tròn 88 nền primary-soft, tiêu đề 16/700,
/// mô tả 14, nút hành động (nếu có). Đặt ở 1/3 trên, không căn giữa màn.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = LucideIcons.inbox,
    required this.title,
    this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: const Alignment(0, -0.4),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: constraints.hasBoundedHeight
                ? constraints.maxHeight * 0.6
                : 280,
          ),
          // Cuộn được khi không gian quá thấp (tab con, bàn phím) → không overflow.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: context.appText.title.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description!,
                    style: context.appText.label.copyWith(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButtonTheme(
                    data: OutlinedButtonThemeData(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                    child: action!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
