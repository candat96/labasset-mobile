import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/format/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/app_sheet.dart';
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
        onPressed: () => _addVendor(context, controller),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _addVendor(BuildContext context, VendorsTabController c) async {
  final selection = await PickerSheet.show<String>(
    context,
    title: 'repairs.vendors.supplier'.tr,
    kind: PickerKind.supplier,
    loader: (q) async {
      final list = await c.catalogs.list('suppliers', q: q, limit: 20);
      return [
        for (final s in list)
          PickerOption(value: s.id, code: s.code, name: s.name),
      ];
    },
  );
  final supplier = selection?.option;
  if (supplier == null || !context.mounted) return;

  await AppSheet.show<void>(
    context,
    builder: (ctx) => SheetForm(
      builder: (context, form) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: 'repairs.vendors.add'.tr),
            Text(supplier.label),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: form.field('engineer'),
              decoration: InputDecoration(
                labelText: 'repairs.vendors.engineer'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('phone'),
              decoration: InputDecoration(
                labelText: 'repairs.vendors.phone'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            MoneyField(
              controller: form.field('quotation'),
              label: 'repairs.vendors.quotation'.tr,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('contract'),
              decoration: InputDecoration(
                labelText: 'repairs.vendors.contract'.tr,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('visitAt'),
              readOnly: true,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) form.field('visitAt').text = formatDate(d);
              },
              decoration: InputDecoration(
                labelText: 'repairs.vendors.visitAt'.tr,
                suffixIcon: const Icon(Icons.event_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: form.field('note'),
              decoration: InputDecoration(labelText: 'repairs.logs.note'.tr),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: form.busy
                  ? null
                  : () async {
                      form.setBusy(true);
                      final quotation = MoneyField.raw(form.text('quotation'));
                      final ok = await c.add(
                        supplierId: supplier.value,
                        engineerName: form.textOrNull('engineer'),
                        engineerPhone: form.textOrNull('phone'),
                        quotationAmount: quotation.isEmpty ? null : quotation,
                        contractNo: form.textOrNull('contract'),
                        visitAt: form.text('visitAt').isEmpty
                            ? null
                            : _iso(form.text('visitAt')),
                        note: form.textOrNull('note'),
                      );
                      form.setBusy(false);
                      if (ok) form.close();
                    },
              child: Text('common.save'.tr),
            ),
          ],
        ),
      ),
    ),
  );
}

String? _iso(String display) {
  final parts = display.split('/');
  if (parts.length != 3) return null;
  return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
}
