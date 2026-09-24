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
import '../ai/ai_status_controller.dart';
import '../notifications/notification_bell.dart';
import 'home_controller.dart';

/// Trang chủ: hero gradient + ô tìm đè hero, KPI cuộn ngang, việc hôm nay,
/// lối tắt 4 cột trực tiếp trên nền trắng.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _heroHeight = 132.0;
  static const _searchOverlap = 22.0;

  static const _shortcuts = <_Shortcut>[
    _Shortcut(
      'reportFault',
      LucideIcons.triangleAlert,
      AppAccent.red,
      dept: true,
      warehouse: true,
    ),
    _Shortcut(
      'stockIssue',
      LucideIcons.packageMinus,
      AppAccent.orange,
      dept: false,
      warehouse: true,
    ),
    _Shortcut(
      'stockReceipt',
      LucideIcons.packagePlus,
      AppAccent.green,
      dept: false,
      warehouse: true,
    ),
    _Shortcut(
      'stocktake',
      LucideIcons.clipboardCheck,
      AppAccent.purple,
      dept: false,
      warehouse: true,
    ),
    _Shortcut(
      'calendar',
      LucideIcons.calendarDays,
      AppAccent.teal,
      dept: true,
      warehouse: true,
    ),
    _Shortcut(
      'equipmentList',
      LucideIcons.microscope,
      AppAccent.brand,
      dept: true,
      warehouse: true,
    ),
    // "Phiếu yêu cầu" chỉ hữu ích cho khoa (kho/VT đã có tab riêng).
    _Shortcut(
      'requests',
      LucideIcons.fileCheck,
      AppAccent.indigo,
      dept: true,
      warehouse: false,
    ),
    _Shortcut(
      'equipmentNew',
      LucideIcons.monitorUp,
      AppAccent.indigo,
      dept: false,
      warehouse: true,
    ),
    _Shortcut(
      'reports',
      LucideIcons.chartPie,
      AppAccent.yellow,
      dept: false,
      warehouse: true,
    ),
    _Shortcut(
      'demand',
      LucideIcons.clipboardList,
      AppAccent.indigo,
      dept: true,
      warehouse: true,
    ),
    _Shortcut(
      'assistant',
      LucideIcons.sparkles,
      AppAccent.pink,
      dept: true,
      warehouse: true,
    ),
  ];

  /// Khoa (DEPT_*) không thấy nghiệp vụ kho trong lối tắt.
  bool get _isDept => !Get.find<SessionStore>().hasRole(Routes.warehouseRoles);

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
    Row(
      children: [
        Expanded(
          child: KpiTile(
            width: double.infinity,
            height: 104,
            label: 'home.alert.brokenShort'.tr,
            value: '${controller.brokenUnassigned}',
            icon: LucideIcons.triangleAlert,
            tone: StatusTone.danger,
            accent: AppAccent.red,
            onTap: () => Get.toNamed('${Routes.repairs}?segment=unassigned'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: KpiTile(
            width: double.infinity,
            height: 104,
            label: 'home.alert.suppliesLowShort'.tr,
            value: '${controller.suppliesAlert}',
            icon: LucideIcons.packageSearch,
            tone: StatusTone.warning,
            accent: AppAccent.orange,
            onTap: () => Get.toNamed(Routes.stockAlerts),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: KpiTile(
            width: double.infinity,
            height: 104,
            label: 'home.alert.calibrationOverdueShort'.tr,
            value: '${controller.calibrationOverdue}',
            icon: LucideIcons.badgeCheck,
            tone: StatusTone.danger,
            accent: AppAccent.purple,
            onTap: () => Get.toNamed(Routes.calibrations),
          ),
        ),
      ],
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
          if (_isDept ? s.dept : s.warehouse)
            _shortcut(s.key, s.icon, s.accent),
      ],
    ),
  ];

  /// Lối tắt; riêng "Trợ lý AI" ẩn khi API tắt (`AiGate`).
  Widget _shortcut(String key, IconData icon, AppAccent accent) {
    final tile = ShortcutTile(
      icon: icon,
      label: 'placeholder.$key'.tr,
      accent: accent,
      onTap: () => Get.toNamed(switch (key) {
        'equipmentList' => Routes.equipmentList,
        'equipmentNew' => Routes.equipmentNew,
        'calendar' => Routes.calendar,
        'stocktake' => Routes.stocktakes,
        'reports' => Routes.reports,
        'requests' => Routes.requests,
        'demand' => Routes.demand,
        'assistant' => Routes.aiConversations,
        'reportFault' => Routes.repairNew,
        'stockIssue' => Routes.stockIssueNew,
        'stockReceipt' => Routes.stockReceiptNew,
        _ => Routes.stock,
      }),
    );
    return key == 'assistant' ? AiGate(child: tile) : tile;
  }
}

/// Hero gradient: logo + tên app + chuông, lời chào, viện · ngày; ô tìm kiếm
/// pill trắng đè nửa ra ngoài mép dưới.
class _Hero extends StatelessWidget {
  const _Hero({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    // Chữ trên gradient luôn trắng (cả dark).
    const white = AppColors.onPrimary;
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
    // Khoa không thấy dòng kiểm kê (nghiệp vụ kho, số vốn dĩ = 0).
    final isDept = !Get.find<SessionStore>().hasRole(Routes.warehouseRoles);
    final groups =
        [
              (
                icon: LucideIcons.wrench,
                accent: AppAccent.brand,
                title: 'home.task.repairsAssigned'.tr,
                total: controller.repairsAssignedTotal,
                route: '${Routes.repairs}?segment=mine',
              ),
              (
                icon: LucideIcons.messageCircleWarning,
                accent: AppAccent.yellow,
                title: 'home.task.repairsPendingResponse'.tr,
                total: controller.repairsPendingResponse,
                route: '${Routes.repairs}?segment=mine',
              ),
              (
                icon: LucideIcons.clockAlert,
                accent: AppAccent.red,
                title: 'home.task.repairsOverdue'.tr,
                total: controller.repairsOverdue,
                route: '${Routes.repairs}?segment=mine',
              ),
              (
                icon: LucideIcons.clipboardCheck,
                accent: AppAccent.purple,
                title: 'home.task.stocktakesOpen'.tr,
                total: controller.stocktakesOpenTotal,
                route: Routes.stocktakes,
              ),
              (
                icon: LucideIcons.calendarClock,
                accent: AppAccent.teal,
                title: 'home.task.maintenanceDue'.tr,
                total: controller.tasksDueTotal,
                route: Routes.maintenanceTasks,
              ),
              (
                icon: LucideIcons.clockAlert,
                accent: AppAccent.orange,
                title: 'home.task.maintenanceOverdue'.tr,
                total: controller.tasksOverdue,
                route: Routes.maintenanceTasks,
              ),
              (
                icon: LucideIcons.fileCheck,
                accent: AppAccent.indigo,
                title: 'home.task.requestsPending'.tr,
                total: controller.requestsPendingTotal,
                route: '${Routes.requests}?segment=pending',
              ),
              (
                icon: LucideIcons.packageCheck,
                accent: AppAccent.green,
                title: 'home.task.requestsApproved'.tr,
                total: controller.requestsApprovedTotal,
                route: '${Routes.requests}?segment=toIssue',
              ),
              (
                icon: LucideIcons.inbox,
                accent: AppAccent.pink,
                title: 'home.task.requestsPendingReceive'.tr,
                total: controller.requestsPendingReceive,
                route: '${Routes.requests}?segment=mine',
              ),
              (
                icon: LucideIcons.clipboardList,
                accent: AppAccent.indigo,
                title: 'home.task.demandToApprove'.tr,
                total: controller.demandToApprove,
                route: Routes.demand,
              ),
              (
                icon: LucideIcons.packageCheck,
                accent: AppAccent.green,
                title: 'home.task.demandToAccept'.tr,
                total: controller.demandToAccept,
                route: Routes.demand,
              ),
              (
                icon: LucideIcons.filePlus2,
                accent: AppAccent.brand,
                title: 'home.task.demandToSubmit'.tr,
                total: controller.demandToSubmit,
                route: Routes.demand,
              ),
            ]
            .where(
              (g) => g.total > 0 && !(isDept && g.route == Routes.stocktakes),
            )
            .toList();
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
            iconAccent: groups[i].accent,
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

/// Một lối tắt trang chủ: khoá i18n + icon + màu, kèm cờ hiển thị theo vai trò.
class _Shortcut {
  const _Shortcut(
    this.key,
    this.icon,
    this.accent, {
    required this.dept,
    required this.warehouse,
  });

  final String key;
  final IconData icon;
  final AppAccent accent;

  /// Hiện với vai trò khoa (DEPT_*) / với vai trò kho-VT (ADM, VT).
  final bool dept;
  final bool warehouse;
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
