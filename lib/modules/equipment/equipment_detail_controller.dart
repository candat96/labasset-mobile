import 'package:get/get.dart';

import '../../data/models/equipment.dart';
import '../../data/repositories/equipment_repository.dart';

class EquipmentDetailController extends GetxController {
  EquipmentDetailController({required this.equipment, required this.id});

  final EquipmentRepository equipment;
  final String id;

  final Rxn<EquipmentSummary> item = Rxn<EquipmentSummary>();
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
      item.value = await equipment.byId(id);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }
}
