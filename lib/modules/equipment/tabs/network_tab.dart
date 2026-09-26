import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/equipment_detail.dart';
import '../../../data/repositories/equipment_repository.dart';

/// Tab "Kết nối": GET/PUT `/:id/network` (PUT thay toàn bộ).
class NetworkTabController extends GetxController {
  NetworkTabController({required this.equipment, required this.id});

  final EquipmentRepository equipment;
  final String id;

  final Rxn<EquipmentNetwork> network = Rxn<EquipmentNetwork>();
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  final ip = TextEditingController();
  final mac = TextEditingController();
  final port = TextEditingController();
  final hostPcName = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final n = await equipment.network(id);
      network.value = n;
      ip.text = n.ip ?? '';
      mac.text = n.mac ?? '';
      port.text = n.port?.toString() ?? '';
      hostPcName.text = n.hostPcName ?? '';
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> save() async {
    final current = network.value;
    if (current == null) return false;
    saving.value = true;
    try {
      await equipment.putNetwork(
        id,
        current.copyWith(
          ip: ip.text.trim(),
          mac: mac.text.trim(),
          port: int.tryParse(port.text.trim()),
          hostPcName: hostPcName.text.trim(),
        ),
      );
      AppSnackbar.success('equipment.network.saved'.tr);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    ip.dispose();
    mac.dispose();
    port.dispose();
    hostPcName.dispose();
    super.onClose();
  }
}

class NetworkTab extends GetView<NetworkTabController> {
  const NetworkTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) return const LoadingList(rows: 4);
      if (controller.error.value != null) {
        return ErrorState(
          error: controller.error.value!,
          onRetry: controller.load,
        );
      }
      final n = controller.network.value;
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SectionCard(
            title: 'equipment.tab.network'.tr,
            child: Column(
              children: [
                TextField(
                  controller: controller.ip,
                  decoration: InputDecoration(
                    labelText: 'equipment.location.ip'.tr,
                    hintText: '192.168.1.10',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: controller.mac,
                  decoration: InputDecoration(
                    labelText: 'equipment.location.mac'.tr,
                    hintText: 'AA:BB:CC:DD:EE:FF',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: controller.port,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'equipment.network.port'.tr,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: controller.hostPcName,
                  decoration: InputDecoration(
                    labelText: 'equipment.network.pc'.tr,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: AppButton.soft(
                          tone: AppButtonTone.primary,
                          label: 'common.retry'.tr,
                          expand: true,
                          onPressed: controller.load,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton.primary(
                          label: 'common.save'.tr,
                          expand: true,
                          onPressed: controller.saving.value
                              ? null
                              : controller.save,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (n != null) ...[
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'equipment.network.other'.tr,
              child: Column(
                children: [
                  _kv(context, 'equipment.network.protocol'.tr, n.protocol),
                  _kv(
                    context,
                    'equipment.network.lis'.tr,
                    n.lisConnected ? 'common.yes'.tr : 'common.no'.tr,
                  ),
                  _kv(context, 'equipment.network.lisNote'.tr, n.lisNote),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      );
    });
  }

  Widget _kv(BuildContext context, String k, String? v) {
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
