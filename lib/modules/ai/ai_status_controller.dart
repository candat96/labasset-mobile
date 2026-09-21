import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ai/ai_models.dart';
import '../../data/repositories/ai_repository.dart';

/// Trạng thái AI dùng chung: ẩn mọi lối vào khi `status.enabled == false`.
class AiStatusController extends GetxController {
  AiStatusController(this.repo);

  final AiRepository repo;

  final Rxn<AiStatus> status = Rxn<AiStatus>();
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  bool get enabled => status.value?.enabled ?? false;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      status.value = await repo.status();
    } catch (e) {
      error.value = e;
      status.value = const AiStatus(enabled: false, apiMissing: false);
    } finally {
      loading.value = false;
    }
  }
}

/// Ẩn lối vào AI khi `status.enabled == false` (chưa đăng ký → vẫn hiện, để
/// test/route lẻ không phụ thuộc bootstrap).
class AiGate extends StatelessWidget {
  const AiGate({super.key, required this.child, this.fallback});

  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AiStatusController>()) return child;
    final controller = Get.find<AiStatusController>();
    return Obx(
      () => controller.enabled ? child : (fallback ?? const SizedBox.shrink()),
    );
  }
}
