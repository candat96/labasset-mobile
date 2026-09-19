import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../data/models/stock.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/supplies_repository.dart';

/// Tra tồn: tìm vật tư/lô theo tên hoặc quét mã.
class StockLookupController extends GetxController {
  StockLookupController({
    required this.supplies,
    required this.stock,
    required this.equipment,
    Future<void> Function(String route)? navigate,
    String? initialQuery,
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r)) {
    if (initialQuery != null && initialQuery.isNotEmpty) {
      query.text = initialQuery;
    }
  }

  final SuppliesRepository supplies;
  final StockRepository stock;
  final EquipmentRepository equipment;
  final Future<void> Function(String route) _navigate;

  final query = TextEditingController();
  final RxList<SupplySummary> supplyResults = <SupplySummary>[].obs;
  final RxList<StockLotSummary> lotResults = <StockLotSummary>[].obs;
  final RxBool loading = false.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxBool searched = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (query.text.isNotEmpty) unawaited(search(query.text));
  }

  Future<void> search(String q) async {
    final term = q.trim();
    if (term.isEmpty) return;
    loading.value = true;
    error.value = null;
    Object? firstError;
    var ok = 0;
    try {
      supplyResults.assignAll((await supplies.list(q: term, limit: 20)).items);
      ok++;
    } catch (e) {
      firstError ??= e;
    }
    try {
      lotResults.assignAll((await stock.lots(q: term, limit: 20)).items);
      ok++;
    } catch (e) {
      firstError ??= e;
    }
    if (ok == 0) error.value = firstError;
    searched.value = true;
    loading.value = false;
  }

  /// Quét: mã máy → hồ sơ máy; mã khác → tìm vật tư/lô.
  Future<void> onScan(String code) async {
    try {
      final qr = await equipment.byQr(code);
      await _navigate(Routes.equipment(qr.id));
      return;
    } catch (_) {
      // không phải token máy → tra vật tư
    }
    query.text = code;
    await search(code);
  }

  Future<void> openSupply(String id) => _navigate(Routes.supply(id));

  @override
  void onClose() {
    query.dispose();
    super.onClose();
  }
}
