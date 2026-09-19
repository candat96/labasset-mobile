import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/repositories/requests_repository.dart';
import '../../data/repositories/stock_repository.dart';

/// Trang tổng quan Kho: cảnh báo theo loại + việc chờ cấp phát.
class StockOverviewController extends GetxController {
  StockOverviewController({required this.stock, required this.requests});

  final StockRepository stock;
  final RequestsRepository requests;

  static const alertTypes = [
    'low_stock',
    'expiring',
    'expired',
    'open_vial_expiring',
    'stale',
  ];

  final RxMap<String, int> alertTotals = <String, int>{}.obs;
  final RxInt pendingIssue = 0.obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final search = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    Object? firstError;
    var ok = 0;
    for (final t in alertTypes) {
      try {
        final page = await stock.alerts(resolved: false, type: t, limit: 1);
        alertTotals[t] = page.total.toInt();
        ok++;
      } catch (e) {
        firstError ??= e;
      }
    }
    try {
      final page = await requests.list(
        status: 'approved,partially_approved',
        limit: 1,
      );
      pendingIssue.value = page.total.toInt();
      ok++;
    } catch (e) {
      firstError ??= e;
    }
    if (ok == 0) error.value = firstError;
    loading.value = false;
  }

  int totalOf(String type) => alertTotals[type] ?? 0;

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}
