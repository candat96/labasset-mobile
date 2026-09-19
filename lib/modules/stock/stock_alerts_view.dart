import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../data/models/stock.dart';
import '../../data/repositories/stock_repository.dart';

/// Danh sách cảnh báo kho `/stock/alerts` (segment theo loại + resolve).
class StockAlertsController extends GetxController {
  StockAlertsController({required this.stock, String? initialType})
    : type = (initialType ?? '').obs;

  final StockRepository stock;

  static const types = [
    'low_stock',
    'expiring',
    'expired',
    'open_vial_expiring',
    'stale',
  ];

  final RxString type;
  final RxList<StockAlertSummary> items = <StockAlertSummary>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final page = await stock.alerts(
        resolved: false,
        type: type.value.isEmpty ? null : type.value,
        limit: 50,
      );
      items.assignAll(page.items);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void setType(String t) {
    type.value = type.value == t ? '' : t;
    load();
  }

  Future<void> resolve(StockAlertSummary alert) async {
    try {
      await stock.resolveAlert(alert.id);
      AppSnackbar.success('stock.alert.resolved'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }
}

class StockAlertsView extends GetView<StockAlertsController> {
  const StockAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('stock.alerts.title'.tr)),
      body: Column(
        children: [
          Obx(
            () => Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final t in StockAlertsController.types)
                  FilterChip(
                    label: Text('stock.alert.$t'.tr),
                    selected: controller.type.value == t,
                    onSelected: (_) => controller.setType(t),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value && controller.items.isEmpty) {
                return const LoadingList();
              }
              if (controller.error.value != null && controller.items.isEmpty) {
                return ErrorState(
                  error: controller.error.value!,
                  onRetry: controller.load,
                );
              }
              if (controller.items.isEmpty) {
                return EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'stock.alert.empty'.tr,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final a = controller.items[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber_outlined,
                          color: a.type == 'expired'
                              ? context.status.danger
                              : context.status.warning,
                        ),
                        title: Text(a.message),
                        subtitle: Text(
                          '${'stock.alert.$a.type'.tr}'
                          '${a.createdAt == null ? '' : ' · ${formatDateTime(a.createdAt)}'}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: a.type == 'stale'
                            ? TextButton(
                                onPressed: () => controller.resolve(a),
                                child: Text('stock.alert.resolve'.tr),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => Get.toNamed(Routes.supply(a.supplyId)),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
