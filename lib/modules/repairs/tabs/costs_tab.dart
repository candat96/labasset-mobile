import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/format/decimal_input.dart';
import '../../../core/format/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/money_field.dart';
import '../../../data/models/repair_detail.dart';
import '../../../data/repositories/repairs_repository.dart';

const kCostCategories = ['parts', 'labor', 'service', 'transport', 'other'];

/// Tab "Chi phí" của phiếu sửa chữa (list + tổng + cảnh báo vượt giá trị).
class CostsTabController extends GetxController {
  CostsTabController({required this.repairs, required this.ticketId});

  final RepairsRepository repairs;
  final String ticketId;

  final RxList<RepairCost> items = <RepairCost>[].obs;
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
      items.assignAll(await repairs.costs(ticketId));
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> add({
    required String category,
    required String description,
    required String amount,
    String? invoiceNo,
    String? invoiceDate,
    String? paidAt,
  }) async {
    try {
      await repairs.addCost(ticketId, {
        'category': category,
        'description': description,
        'amount': amount,
        'invoiceNo': ?invoiceNo,
        'invoiceDate': ?invoiceDate,
        'paidAt': ?paidAt,
      });
      AppSnackbar.success('repairs.costs.saved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }
}

class CostsTab extends GetView<CostsTabController> {
  const CostsTab({super.key});

  @override
  String? get tag => Get.parameters['id'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.loading.value) return const LoadingList();
        if (controller.error.value != null) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.items.isEmpty) {
          return EmptyState(
            icon: Icons.payments_outlined,
            title: 'repairs.costs.empty'.tr,
          );
        }
        final total = controller.items.fold<Decimal>(
          Decimal.zero,
          (sum, c) => sum + (parseDecimalInput(c.amount) ?? Decimal.zero),
        );
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Card(
                child: ListTile(
                  title: Text('repairs.costs.total'.tr),
                  trailing: Text(
                    formatVnd(total.toString()),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final c in controller.items)
                Card(
                  child: ListTile(
                    title: Text(c.description),
                    subtitle: Text(
                      '${'repairs.costs.category.${c.category}'.tr}'
                      '${c.invoiceNo == null ? '' : ' · ${c.invoiceNo}'}',
                    ),
                    trailing: Text(
                      formatVnd(c.amount),
                      style: TextStyle(color: context.status.info),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addCost',
        tooltip: 'repairs.costs.add'.tr,
        onPressed: () => _addCost(controller),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _addCost(CostsTabController c) async {
  var category = 'parts';
  final description = TextEditingController();
  final amount = TextEditingController();
  final invoiceNo = TextEditingController();
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'repairs.costs.add'.tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final s in kCostCategories)
                    ChoiceChip(
                      label: Text('repairs.costs.category.$s'.tr),
                      selected: category == s,
                      onSelected: (v) {
                        if (v) setState(() => category = s);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: description,
                decoration: InputDecoration(
                  labelText: 'repairs.costs.description'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              MoneyField(controller: amount, label: 'repairs.costs.amount'.tr),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: invoiceNo,
                decoration: InputDecoration(
                  labelText: 'repairs.costs.invoiceNo'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  if (description.text.trim().isEmpty ||
                      MoneyField.raw(amount.text).isEmpty) {
                    return;
                  }
                  final ok = await c.add(
                    category: category,
                    description: description.text.trim(),
                    amount: MoneyField.raw(amount.text),
                    invoiceNo: invoiceNo.text.trim().isEmpty
                        ? null
                        : invoiceNo.text.trim(),
                  );
                  if (ok) Get.back();
                },
                child: Text('common.save'.tr),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.colorScheme.surface,
  );
  description.dispose();
  amount.dispose();
  invoiceNo.dispose();
}
