import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/format/format.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import '../../core/widgets/status_badge.dart';
import 'stock_lookup_controller.dart';

/// Tra tồn `/stock/lookup`.
class StockLookupView extends GetView<StockLookupController> {
  const StockLookupView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('stock.lookup.title'.tr),
        actions: [
          IconButton(
            tooltip: 'scan.title'.tr,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final codes = await Get.toNamed<List<String>>(
                Routes.scan,
                arguments: {'continuous': true},
              );
              final code = codes?.firstOrNull;
              if (code != null) await controller.onScan(code);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: controller.query,
              textInputAction: TextInputAction.search,
              onSubmitted: controller.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'stock.lookup.hint'.tr,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => controller.search(controller.query.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) return const LoadingList();
              if (controller.error.value != null) {
                return ErrorState(
                  error: controller.error.value!,
                  onRetry: () => controller.search(controller.query.text),
                );
              }
              if (!controller.searched.value) {
                return EmptyState(
                  icon: Icons.search,
                  title: 'stock.lookup.hint'.tr,
                );
              }
              if (controller.supplyResults.isEmpty &&
                  controller.lotResults.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off,
                  title: 'picker.empty'.tr,
                );
              }
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  if (controller.supplyResults.isNotEmpty) ...[
                    Text(
                      'stock.lookup.supplies'.tr,
                      style: theme.textTheme.titleSmall,
                    ),
                    for (final s in controller.supplyResults)
                      ListTile(
                        title: Text('${s.code} — ${s.name}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => controller.openSupply(s.id),
                      ),
                  ],
                  if (controller.lotResults.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'stock.lookup.lots'.tr,
                      style: theme.textTheme.titleSmall,
                    ),
                    for (final l in controller.lotResults)
                      ListTile(
                        title: Text('${'scan.lot.lotNo'.tr}: ${l.lotNo}'),
                        subtitle: Text(
                          '${'scan.lot.qty'.tr}: ${formatVnd(l.available, symbol: false)}'
                          '${l.expiresAt == null ? '' : ' · ${'scan.lot.expiry'.tr}: ${formatDate(l.expiresAt)}'}',
                        ),
                        trailing: StatusBadge(
                          tone: l.status == 'available'
                              ? StatusTone.success
                              : l.status == 'expired'
                              ? StatusTone.danger
                              : StatusTone.warning,
                          label: 'status.lot.${l.status}'.tr,
                        ),
                        onTap: () => controller.openSupply(l.supplyId),
                      ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
