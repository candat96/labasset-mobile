import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/format/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../data/models/repair_detail.dart';
import '../../../data/repositories/catalogs_repository.dart';
import '../../../data/repositories/repairs_repository.dart';

/// Tab "Thuê ngoài" của phiếu sửa chữa.
class VendorsTabController extends GetxController {
  VendorsTabController({
    required this.repairs,
    required this.catalogs,
    required this.ticketId,
  });

  final RepairsRepository repairs;
  final CatalogsRepository catalogs;
  final String ticketId;

  final RxList<RepairVendor> items = <RepairVendor>[].obs;
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
      items.assignAll(await repairs.vendors(ticketId));
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> add({
    required String supplierId,
    String? engineerName,
    String? engineerPhone,
    String? quotationAmount,
    String? contractNo,
    String? visitAt,
    String? note,
  }) async {
    try {
      await repairs.addVendor(ticketId, {
        'supplierId': supplierId,
        'engineerName': ?engineerName,
        'engineerPhone': ?engineerPhone,
        'quotationAmount': ?quotationAmount,
        'contractNo': ?contractNo,
        'visitAt': ?visitAt,
        'note': ?note,
      });
      AppSnackbar.success('repairs.vendors.saved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }
}

class VendorsTab extends GetView<VendorsTabController> {
  const VendorsTab({super.key});

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
            icon: Icons.engineering_outlined,
            title: 'repairs.vendors.empty'.tr,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: controller.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final v = controller.items[i];
              return Card(
                child: ListTile(
                  title: Text(v.engineerName ?? v.supplierId ?? '—'),
                  subtitle: Text(
                    [
                      if (v.engineerPhone != null) v.engineerPhone!,
                      if (v.quotationAmount != null)
                        formatVnd(v.quotationAmount),
                      if (v.visitAt != null) formatDate(v.visitAt),
                    ].join(' · '),
                  ),
                  isThreeLine: v.note != null,
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'addVendor',
        tooltip: 'repairs.vendors.add'.tr,
        onPressed: () => _addVendor(controller),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _addVendor(VendorsTabController c) async {
  final selection = await PickerSheet.show<String>(
    title: 'repairs.vendors.supplier'.tr,
    loader: (q) async {
      final list = await c.catalogs.list('suppliers', q: q, limit: 20);
      return [
        for (final s in list)
          PickerOption(value: s.id, code: s.code, name: s.name),
      ];
    },
  );
  final supplier = selection?.option;
  if (supplier == null) return;

  final engineer = TextEditingController();
  final phone = TextEditingController();
  final quotation = TextEditingController();
  final contract = TextEditingController();
  final visitAt = TextEditingController();
  final note = TextEditingController();
  await Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'repairs.vendors.add'.tr,
                style: Get.theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(supplier.label),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: engineer,
                decoration: InputDecoration(
                  labelText: 'repairs.vendors.engineer'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: phone,
                decoration: InputDecoration(
                  labelText: 'repairs.vendors.phone'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              MoneyField(
                controller: quotation,
                label: 'repairs.vendors.quotation'.tr,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: contract,
                decoration: InputDecoration(
                  labelText: 'repairs.vendors.contract'.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: visitAt,
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) visitAt.text = formatDate(d);
                },
                decoration: InputDecoration(
                  labelText: 'repairs.vendors.visitAt'.tr,
                  suffixIcon: const Icon(Icons.event_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: note,
                decoration: InputDecoration(labelText: 'repairs.logs.note'.tr),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final ok = await c.add(
                    supplierId: supplier.value,
                    engineerName: engineer.text.trim().isEmpty
                        ? null
                        : engineer.text.trim(),
                    engineerPhone: phone.text.trim().isEmpty
                        ? null
                        : phone.text.trim(),
                    quotationAmount: MoneyField.raw(quotation.text).isEmpty
                        ? null
                        : MoneyField.raw(quotation.text),
                    contractNo: contract.text.trim().isEmpty
                        ? null
                        : contract.text.trim(),
                    visitAt: visitAt.text.trim().isEmpty
                        ? null
                        : _iso(visitAt.text),
                    note: note.text.trim().isEmpty ? null : note.text.trim(),
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
  engineer.dispose();
  phone.dispose();
  quotation.dispose();
  contract.dispose();
  visitAt.dispose();
  note.dispose();
}

String? _iso(String display) {
  final parts = display.split('/');
  if (parts.length != 3) return null;
  return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
}
