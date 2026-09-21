import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/storage/session_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_list_tile.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/shortcut_tile.dart';
import '../../core/widgets/status_badge.dart';
import '../notifications/notification_bell.dart';
import 'home_controller.dart';

/// Trang chủ: hero gradient + ô tìm đè hero, KPI cuộn ngang, việc hôm nay,
/// lối tắt 4 cột trực tiếp trên nền trắng.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _heroHeight = 132.0;
  static const _searchOverlap = 22.0;

  static const _shortcuts = [
    (key: 'reportFault', icon: LucideIcons.triangleAlert),
    (key: 'stockIssue', icon: LucideIcons.packageMinus),
    (key: 'stockReceipt', icon: LucideIcons.packagePlus),
    (key: 'stocktake', icon: LucideIcons.clipboardCheck),
    (key: 'calendar', icon: LucideIcons.calendarDays),
    (key: 'equipmentNew', icon: LucideIcons.monitorUp),
    (key: 'reports', icon: LucideIcons.chartPie),
    (key: 'assistant', icon: LucideIcons.sparkles),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Obx(() {
          final empty = controller.data.value == null;
          final firstLoad = empty && controller.cachedAt.value == null;
          Widget body;
          if (controller.loading.value && firstLoad) {
            body = const SliverFillRemaining(child: LoadingList(rows: 6));
          } else if (controller.error.value != null && firstLoad) {
            body = SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorState(
                error: controller.error.value!,
                onRetry: controller.load,
              ),
            );
          } else {
            body = SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                _searchOverlap + AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl * 2,
              ),
              sliver: SliverList.list(children: _content(context)),
            );
          }
          return RefreshIndicator(
            onRefresh: controller.load,
            edgeOffset: _heroHeight,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Hero(controller: controller)),
                body,
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _content(BuildContext context) => [
    if (controller.cachedAt.value != null)
      _OfflineBanner(cachedAt: controller.cachedAt.value!),
    SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        children: [
          KpiTile(
            label: 'home.alert.brokenShort'.tr,
            value: '${controller.brokenUnassigned}',
            icon: LucideIcons.triangleAlert,
            tone: StatusTone.danger,
            onTap: () => Get.toNamed('${Routes.repairs}?segment=unassigned'),
          ),
          const SizedBox(width: AppSpacing.md),
          KpiTile(
            label: 'home.alert.suppliesLowShort'.tr,
            value: '${controller.suppliesAlert}',
            icon: LucideIcons.packageSearch,
            tone: StatusTone.warning,
            onTap: () => Get.toNamed(Routes.stockAlerts),
          ),
          const SizedBox(width: AppSpacing.md),
          KpiTile(
            label: 'home.alert.calibrationOverdueShort'.tr,
            value: '${controller.calibrationOverdue}',
            icon: LucideIcons.badgeCheck,
            tone: StatusTone.danger,
            onTap: () => Get.toNamed(Routes.calibrations),
          ),
        ],
      ),
    ),
    const SizedBox(height: AppSpacing.xl),
    SectionCard(
      title: 'home.myTasks'.tr,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: _WorkGroups(controller: controller),
    ),
    const SizedBox(height: AppSpacing.xl),
    Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: SectionTitle('home.shortcuts'.tr),
    ),
    const SizedBox(height: AppSpacing.sm),
    GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      childAspectRatio: 0.92,
      children: [
        for (final s in _shortcuts)
          ShortcutTile(
            icon: s.icon,
            label: 'placeholder.${s.key}'.tr,
            onTap: () => Get.toNamed(switch (s.key) {
              'equipmentNew' => Routes.equipmentNew,
              'calendar' => Routes.calendar,
              'stocktake' => Routes.stocktakes,
              'reports' => Routes.reports,
              'assistant' => Routes.ai,
              'reportFault' => Routes.repairNew,
              'stockIssue' => Routes.stockIssueNew,
              'stockReceipt' => Routes.stockReceiptNew,
              _ => Routes.stock,
            }),
          ),
      ],
    ),
  ];
}

/// Hero gradient: logo + tên app + chuông, lời chào, viện · ngày; ô tìm kiếm
/// pill trắng đè nửa ra ngoài mép dưới.
class _Hero extends StatelessWidget {
  const _Hero({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final scheme = Theme.of(context).colorScheme;
    final white = scheme.onPrimary;
    final store = Get.find<SessionStore>();
    final now = DateTime.now();
    final dateLabel =
        '${'home.weekday.${now.weekday}'.tr}, ${formatDate(now).substring(0, 5)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: HomeView._searchOverlap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: BoxConstraints(minHeight: top + HomeView._heroHeight),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              top + AppSpacing.sm,
              AppSpacing.sm,
              HomeView._searchOverlap + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: context.brandGradient,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.hero),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset('assets/brand/logo-512.png'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'app.name'.tr,
                      style: context.appText.bodyStrong.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: white,
                      ),
                    ),
                    const Spacer(),
                    NotificationBell(color: white),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Obx(() {
                  final name = store.user.value?.fullName ?? '';
                  final hospital = controller.hospitalName.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home.greeting'.trParams({'name': name}),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.appText.title.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hospital == null || hospital.isEmpty
                              ? dateLabel
                              : '$hospital · $dateLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.appText.label.copyWith(
                            color: white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: -HomeView._searchOverlap,
            child: _SearchPill(onTap: () => Get.toNamed(Routes.search)),
          ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'search.title'.tr,
      child: AppCard(
        floating: true,
        radius: AppRadius.chip,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Icon(LucideIcons.search, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'home.searchHint'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appText.body.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.cachedAt});

  final DateTime cachedAt;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForTone(context, StatusTone.warning);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.cloudOff, size: 18, color: palette.color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'home.cachedAt'.trParams({'time': formatDateTime(cachedAt)}),
              style: context.appText.label.copyWith(color: palette.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkGroups extends StatelessWidget {
  const _WorkGroups({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final groups = [
      (
        icon: LucideIcons.wrench,
        title: 'home.task.repairsAssigned'.tr,
        total: controller.repairsAssignedTotal,
        route: '${Routes.repairs}?segment=mine',
      ),
      (
        icon: LucideIcons.messageCircleWarning,
        title: 'home.task.repairsPendingResponse'.tr,
        total: controller.repairsPendingResponse,
        route: '${Routes.repairs}?segment=mine',
      ),
      (
        icon: LucideIcons.clockAlert,
        title: 'home.task.repairsOverdue'.tr,
        total: controller.repairsOverdue,
        route: '${Routes.repairs}?segment=mine',
      ),
      (
        icon: LucideIcons.clipboardCheck,
        title: 'home.task.stocktakesOpen'.tr,
        total: controller.stocktakesOpenTotal,
        route: Routes.stocktakes,
      ),
      (
        icon: LucideIcons.calendarClock,
        title: 'home.task.maintenanceDue'.tr,
        total: controller.tasksDueTotal,
        route: Routes.maintenanceTasks,
      ),
      (
        icon: LucideIcons.clockAlert,
        title: 'home.task.maintenanceOverdue'.tr,
        total: controller.tasksOverdue,
        route: Routes.maintenanceTasks,
      ),
      (
        icon: LucideIcons.fileCheck,
        title: 'home.task.requestsPending'.tr,
        total: controller.requestsPendingTotal,
        route: '${Routes.requests}?segment=pending',
      ),
      (
        icon: LucideIcons.packageCheck,
        title: 'home.task.requestsApproved'.tr,
        total: controller.requestsApprovedTotal,
        route: '${Routes.requests}?segment=toIssue',
      ),
      (
        icon: LucideIcons.inbox,
        title: 'home.task.requestsPendingReceive'.tr,
        total: controller.requestsPendingReceive,
        route: '${Routes.requests}?segment=mine',
      ),
    ].where((g) => g.total > 0).toList();
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              LucideIcons.partyPopper,
              size: 20,
              color: context.status.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('home.noWork'.tr, style: context.appText.body),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < groups.length; i++)
          AppListTile(
            accent: true,
            icon: groups[i].icon,
            title: groups[i].title,
            trailing: _CountPill(count: groups[i].total),
            onTap: () => Get.toNamed(groups[i].route),
            showDivider: i != groups.length - 1,
          ),
      ],
    );
  }
}

/// Số lượng trong pill primary-soft, chữ 13/700 on-primary-container.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '$count',
        style: context.appText.label.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
