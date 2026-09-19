import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/cache/kv_cache.dart';
import '../../data/models/equipment.dart';
import '../../data/models/repair_detail.dart';
import '../../data/repositories/departments_repository.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/repairs_repository.dart';
import '../../data/repositories/stock_repository.dart';

/// Báo cáo nhanh `/reports`: thẻ số liệu ghép API + máy theo khoa (cache 1h).
class ReportsController extends GetxController {
  ReportsController({
    required this.equipment,
    required this.repairs,
    required this.stock,
    required this.departments,
    this.cache,
  });

  final EquipmentRepository equipment;
  final RepairsRepository repairs;
  final StockRepository stock;
  final DepartmentsRepository departments;
  final KvCache? cache;

  static const statuses = [
    'active',
    'broken',
    'awaiting_parts',
    'suspended',
    'retired',
    'disposed',
  ];
  static const cacheTtl = Duration(hours: 1);

  final RxMap<String, int> equipmentByStatus = <String, int>{}.obs;
  final Rxn<RepairStats> monthStats = Rxn<RepairStats>();
  final RxList<WorkloadItem> workload = <WorkloadItem>[].obs;
  final RxInt alertsTotal = 0.obs;
  final RxnString stockValue = RxnString();

  final RxnString departmentId = RxnString();
  final RxnString departmentName = RxnString();
  final RxList<EquipmentSummary> machines = <EquipmentSummary>[].obs;
  final Rxn<DateTime> machinesCachedAt = Rxn<DateTime>();
  final machinesSearch = TextEditingController();

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
    Object? firstError;
    var ok = 0;

    for (final s in statuses) {
      try {
        equipmentByStatus[s] = (await equipment.count(status: s)).toInt();
        ok++;
      } catch (e) {
        firstError ??= e;
      }
    }
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1).toUtc().toIso8601String();
    final to = now.toUtc().toIso8601String();
    try {
      monthStats.value = await repairs.stats(from: from, to: to);
      ok++;
    } catch (e) {
      firstError ??= e;
    }
    try {
      workload.assignAll(await repairs.workload());
      ok++;
    } catch (e) {
      firstError ??= e;
    }
    try {
      alertsTotal.value = (await stock.alerts(
        resolved: false,
        limit: 1,
      )).total.toInt();
      ok++;
    } catch (e) {
      firstError ??= e;
    }
    if (ok == 0) error.value = firstError;
    loading.value = false;
  }

  Future<void> pickDepartment() async {
    final list = await departments.list(limit: 50);
    if (list.isEmpty) return;
    final d = await Get.bottomSheet<dynamic>(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'reports.department'.tr,
                style: Get.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final x in list)
                    ListTile(
                      title: Text('${x.code} — ${x.name}'),
                      onTap: () => Get.back(result: x),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
    );
    if (d == null) return;
    departmentId.value = d.id as String;
    departmentName.value = d.name as String;
    await loadMachines();
  }

  Future<void> loadMachines() async {
    final id = departmentId.value;
    if (id == null) return;
    final key = 'reports.dept.$id';
    try {
      final page = await equipment.listByDepartment(id);
      machines.assignAll(page.items);
      machinesCachedAt.value = null;
      await cache?.put(key, {
        'items': page.items.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      final cached = await cache?.get(key);
      if (cached != null) {
        final raw = cached.value['items'];
        if (raw is List) {
          machines.assignAll(
            raw
                .whereType<Map>()
                .map(
                  (m) =>
                      EquipmentSummary.fromJson(Map<String, dynamic>.from(m)),
                )
                .toList(),
          );
          machinesCachedAt.value = cached.updatedAt;
        }
      } else {
        error.value = e;
      }
    }
  }

  /// Danh sách báo cáo cố định (hợp đồng D1) — API `/v1/reports` chưa có.
  static const reportKeys = [
    ('equipment_inventory', 'reports.key.equipment_inventory'),
    ('equipment_maintenance', 'reports.key.equipment_maintenance'),
    ('repairs_summary', 'reports.key.repairs_summary'),
    ('stock_inventory', 'reports.key.stock_inventory'),
    ('stock_movement', 'reports.key.stock_movement'),
    ('calibration_due', 'reports.key.calibration_due'),
  ];

  @override
  void onClose() {
    machinesSearch.dispose();
    super.onClose();
  }
}
