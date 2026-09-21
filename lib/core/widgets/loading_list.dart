import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Skeleton danh sách (giữ chiều cao để tránh nhảy layout), nhấp nháy nhẹ.
class LoadingList extends StatefulWidget {
  const LoadingList({super.key, this.rows = 5, this.height = 72});

  final int rows;
  final double height;

  @override
  State<LoadingList> createState() => _LoadingListState();
}

class _LoadingListState extends State<LoadingList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.isDark ? AppColors.mutedDark : AppColors.segment;
    return Semantics(
      label: 'common.loading'.tr,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: widget.rows,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, _) => Container(
            height: widget.height,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Bar(width: 90, color: color),
                _Bar(width: 220, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.color});
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.chip),
    ),
  );
}
