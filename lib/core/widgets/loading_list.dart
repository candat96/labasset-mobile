import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Skeleton danh sách (giữ chiều cao để tránh nhảy layout).
class LoadingList extends StatelessWidget {
  const LoadingList({super.key, this.rows = 5, this.height = 56});

  final int rows;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: 'Đang tải',
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: rows,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
