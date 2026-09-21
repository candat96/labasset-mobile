import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/cache/kv_cache.dart';
import '../../core/services/pdf_file_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/equipment.dart';
import '../../data/models/report.dart';
import '../../data/repositories/departments_repository.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/reports_repository.dart';

typedef ReportFileAction = Future<void> Function(File file);
typedef ReportFileWriter = Future<File> Function(ReportExport report);

/// Báo cáo nhanh từ D1; máy theo khoa vẫn có cache riêng để dùng thực địa.
class ReportsController extends GetxController {
  ReportsController({
    required this.reports,
    required this.equipment,
    required this.departments,
    this.cache,
    ReportFileAction? openFile,
    ReportFileAction? shareFile,
    ReportFileWriter? writeFile,
  }) : _openFile = openFile ?? PdfFileService.open,
       _shareFile = shareFile ?? PdfFileService.share,
       _writeFile = writeFile ?? _writeReportFile;

  final ReportsRepository reports;
  final EquipmentRepository equipment;
  final DepartmentsRepository departments;
  final KvCache? cache;
  final ReportFileAction _openFile;
  final ReportFileAction _shareFile;
  final ReportFileWriter _writeFile;
  static const cacheTtl = Duration(hours: 1);

  final RxList<DashboardCard> cards = <DashboardCard>[].obs;
  final RxList<ReportMeta> reportList = <ReportMeta>[].obs;
  final RxnString generatedAt = RxnString();
  final RxnString exportingKey = RxnString();

  final RxnString departmentId = RxnString();
  final RxnString departmentName = RxnString();
  final RxList<EquipmentSummary> machines = <EquipmentSummary>[].obs;
  final Rxn<DateTime> machinesCachedAt = Rxn<DateTime>();
  final machinesSearch = TextEditingController();
  final reportFrom = TextEditingController(text: _firstDayOfMonth());
  final reportTo = TextEditingController(text: _today());

  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    Object? firstError;
    var loaded = 0;
    await Future.wait([
      () async {
        try {
          final dashboard = await reports.dashboard();
          cards.assignAll(dashboard.cards);
          generatedAt.value = dashboard.generatedAt;
          loaded++;
        } catch (e) {
          firstError ??= e;
        }
      }(),
      () async {
        try {
          reportList.assignAll(await reports.list());
          loaded++;
        } catch (e) {
          firstError ??= e;
        }
      }(),
    ]);
    if (loaded == 0) error.value = firstError;
    loading.value = false;
  }

  Future<void> pickDepartment() async {
    final list = await departments.list(limit: 50);
    if (list.isEmpty) return;
    final selected = await Get.bottomSheet<dynamic>(
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
                  for (final item in list)
                    ListTile(
                      title: Text('${item.code} — ${item.name}'),
                      onTap: () => Get.back(result: item),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
    );
    if (selected == null) return;
    departmentId.value = selected.id as String;
    departmentName.value = selected.name as String;
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
      if (cached == null) {
        error.value = e;
        return;
      }
      final raw = cached.value['items'];
      if (raw is List) {
        machines.assignAll(
          raw.whereType<Map>().map(
            (item) =>
                EquipmentSummary.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
        machinesCachedAt.value = cached.updatedAt;
      }
    }
  }

  Future<void> chooseExport(ReportMeta report) async {
    final choice = await Get.bottomSheet<String>(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: reportFrom,
                      decoration: InputDecoration(
                        labelText: 'reports.from'.tr,
                        hintText: 'reports.dateHint'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: reportTo,
                      decoration: InputDecoration(
                        labelText: 'reports.to'.tr,
                        hintText: 'reports.dateHint'.tr,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text('reports.openXlsx'.tr),
              onTap: () => Get.back(result: 'open:xlsx'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text('reports.shareXlsx'.tr),
              onTap: () => Get.back(result: 'share:xlsx'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text('reports.openPdf'.tr),
              onTap: () => Get.back(result: 'open:pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text('reports.sharePdf'.tr),
              onTap: () => Get.back(result: 'share:pdf'),
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.colorScheme.surface,
    );
    if (choice == null) return;
    final parts = choice.split(':');
    await export(report, format: parts[1], share: parts[0] == 'share');
  }

  Future<bool> export(
    ReportMeta report, {
    required String format,
    required bool share,
  }) async {
    exportingKey.value = report.key;
    try {
      final result = await reports.export(
        report.key,
        format: format,
        departmentId: departmentId.value,
        from: reportFrom.text.trim(),
        to: reportTo.text.trim(),
      );
      final file = await _writeFile(result);
      await (share ? _shareFile(file) : _openFile(file));
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    } finally {
      exportingKey.value = null;
    }
  }

  @override
  void onClose() {
    machinesSearch.dispose();
    reportFrom.dispose();
    reportTo.dispose();
    super.onClose();
  }
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _firstDayOfMonth() {
  final now = DateTime.now();
  return _date(DateTime(now.year, now.month));
}

String _today() => _date(DateTime.now());

Future<File> _writeReportFile(ReportExport report) async {
  final dir = await getTemporaryDirectory();
  final safeName = report.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
  final file = File('${dir.path}/$safeName');
  await file.writeAsBytes(report.bytes, flush: true);
  return file;
}
