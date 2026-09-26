import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/list_item_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/stock_issue.dart';
import '../../data/repositories/stock_repository.dart';

/// Danh sách phiếu xuất kho.
class IssuesController extends GetxController {
  IssuesController({required this.stock});

  final StockRepository stock;

  final RxnString statusFilter = RxnString();
  final RxList<StockIssue> items = <StockIssue>[].obs;
  final RxInt total = 0.obs;
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
      final page = await stock.issues(status: statusFilter.value, limit: 30);
      items.assignAll(page.items);
      total.value = page.total.toInt();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void setStatus(String? s) {
    statusFilter.value = s;
    load();
  }
}

class IssuesView extends GetView<IssuesController> {
  const IssuesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('stock.issues.title'.tr),
        actions: [
          IconButton(
            tooltip: 'common.add'.tr,
            icon: const Icon(LucideIcons.plus),
            onPressed: () => Get.toNamed('/stock/issues/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(
            () => Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final s in [null, 'draft', 'posted', 'cancelled'])
                  ChoiceChip(
                    label: Text(
                      s == null
                          ? 'repairs.segment.all'.tr
                          : 'status.receipt.$s'.tr,
                    ),
                    selected: controller.statusFilter.value == s,
                    onSelected: (_) => controller.setStatus(s),
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
                  icon: LucideIcons.upload,
                  title: 'common.empty'.tr,
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
                    final x = controller.items[i];
                    return ListItemCard(
                      title: x.code,
                      badge: StatusBadge(
                        tone: switch (x.status) {
                          'posted' => StatusTone.success,
                          'cancelled' => StatusTone.danger,
                          _ => StatusTone.warning,
                        },
                        label: 'status.receipt.${x.status}'.tr,
                      ),
                      metas: [
                        ListMeta(
                          LucideIcons.layers,
                          '${'stock.issue.type.${x.type}'.tr}'
                          ' · ${x.items.length} ${'stock.issue.lines'.tr}'
                          '${x.fefoWarning ? ' · ⚠ FEFO' : ''}',
                        ),
                      ],
                      onTap: () async {
                        await Get.toNamed('/stock/issues/${x.id}');
                        await controller.load();
                      },
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
