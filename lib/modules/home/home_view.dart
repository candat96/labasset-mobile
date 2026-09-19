import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../notifications/notification_bell.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _shortcuts = [
    (
      key: 'equipmentList',
      icon: Icons.biotech_outlined,
      route: '/placeholder/equipmentList',
    ),
    (key: 'repairs', icon: Icons.build_outlined, route: '/placeholder/repairs'),
    (
      key: 'maintenance',
      icon: Icons.event_available_outlined,
      route: '/placeholder/maintenance',
    ),
    (
      key: 'stock',
      icon: Icons.inventory_2_outlined,
      route: '/placeholder/stock',
    ),
    (
      key: 'requests',
      icon: Icons.description_outlined,
      route: '/placeholder/requests',
    ),
    (
      key: 'stocktake',
      icon: Icons.fact_check_outlined,
      route: '/placeholder/stocktake',
    ),
    (
      key: 'reports',
      icon: Icons.pie_chart_outline,
      route: '/placeholder/reports',
    ),
    (
      key: 'assistant',
      icon: Icons.smart_toy_outlined,
      route: '/placeholder/assistant',
    ),
    (key: 'search', icon: Icons.search, route: '/placeholder/search'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.hospitalName.value ?? 'app.name'.tr)),
        actions: const [NotificationBell()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _StatCard(
            title: 'home.myTasks'.tr,
            stats: controller.myTasks,
            isMock: controller.isMock,
            color: context.status.info,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatCard(
            title: 'home.alerts'.tr,
            stats: controller.alerts,
            isMock: controller.isMock,
            color: context.status.warning,
          ),
          if (controller.isMock) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('home.mockNote'.tr, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('home.shortcuts'.tr, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.1,
            children: [
              for (final s in _shortcuts)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () => Get.toNamed(s.route),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(s.icon, color: theme.colorScheme.primary),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'placeholder.${s.key}'.tr,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl * 2),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.stats,
    required this.isMock,
    required this.color,
  });

  final String title;
  final List<HomeStat> stats;
  final bool isMock;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                if (isMock)
                  Chip(
                    label: Text('common.mock'.tr),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final s in stats)
              InkWell(
                onTap: () => Get.toNamed(s.route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.key.tr,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${s.value}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
