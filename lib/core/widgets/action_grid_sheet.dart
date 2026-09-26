import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_sheet.dart';
import 'icon_chip.dart';
import 'status_badge.dart';

/// Một thao tác trong [ActionGridSheet].
class SheetAction {
  const SheetAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
}

/// Nhóm thao tác có tiêu đề nhỏ (uppercase); tiêu đề null = không hiện.
class SheetActionGroup {
  const SheetActionGroup({this.title, required this.actions});

  final String? title;
  final List<SheetAction> actions;
}

/// Bottom sheet lưới 3 cột (chip icon 44 + nhãn 12/600, ô ≥ 88) cho màn có
/// nhiều hơn 3 hành động. Đóng sheet rồi mới chạy thao tác.
class ActionGridSheet {
  ActionGridSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<SheetActionGroup> groups,
  }) {
    return AppSheet.show<void>(
      context,
      builder: (ctx) => ActionGridBody(title: title, groups: groups),
    );
  }
}

/// Nội dung lưới thao tác (tách để test).
class ActionGridBody extends StatelessWidget {
  const ActionGridBody({super.key, required this.title, required this.groups});

  final String title;
  final List<SheetActionGroup> groups;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: title),
          for (final g in groups) ...[
            if (g.title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Text(g.title!.toUpperCase(), style: text.section),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                children: [for (final a in g.actions) _ActionCell(action: a)],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({required this.action});

  final SheetAction action;

  @override
  Widget build(BuildContext context) {
    final danger = action.danger;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      onTap: () {
        AppSheet.close(context);
        action.onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconChip(
                icon: action.icon,
                size: 44,
                iconSize: 22,
                radius: AppRadius.card,
                tone: danger ? StatusTone.danger : null,
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: danger ? context.status.danger : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
