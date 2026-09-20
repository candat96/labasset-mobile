import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import '../../core/services/attachment_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/picker_sheet.dart';
import '../../data/models/maintenance.dart';
import '../../data/repositories/calibrations_repository.dart';
import '../../data/repositories/catalogs_repository.dart';

/// Danh sách kiểm định `/calibrations` + ghi kết quả.
class CalibrationsController extends GetxController {
  CalibrationsController({
    required this.repo,
    required this.catalogs,
    required this.attachments,
    this.userId = '',
  });

  final CalibrationsRepository repo;
  final CatalogsRepository catalogs;
  final AttachmentService attachments;
  final String userId;

  final RxnString statusFilter = RxnString();
  final RxnString resultFilter = RxnString();
  final RxBool dueSoonOnly = false.obs;
  final RxList<Calibration> items = <Calibration>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;
  final RxBool uploadingCertificate = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final page = await repo.list(
        status: statusFilter.value,
        result: resultFilter.value,
        dueBefore: dueSoonOnly.value
            ? DateTime.now()
                  .add(const Duration(days: 30))
                  .toUtc()
                  .toIso8601String()
            : null,
        limit: 30,
      );
      items.assignAll(page.items);
      total.value = page.total.toInt();
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void setPreset({String? status, String? result, bool? dueSoon}) {
    statusFilter.value = status;
    resultFilter.value = result;
    if (dueSoon != null) dueSoonOnly.value = dueSoon;
    load();
  }

  Future<List<PickerOption<String>>> loadAgencies(String q) async {
    final items = await catalogs.list('calibration-agencies', q: q);
    return [
      for (final item in items)
        PickerOption(value: item.id, code: item.code, name: item.name),
    ];
  }

  Future<String?> uploadCertificate(Calibration calibration) async {
    final picked = await attachments.pickCertificateBytes();
    if (picked == null) return null;
    uploadingCertificate.value = true;
    try {
      final uploaded = await attachments.uploadBytes(
        entityType: 'calibration',
        entityId: calibration.id,
        kind: 'calibration/certificate',
        name: picked.name,
        mime: picked.mime,
        bytes: picked.bytes,
        queueOnOffline: false,
      );
      return uploaded.attachment?.fileId;
    } catch (e) {
      AppSnackbar.error(e);
      return null;
    } finally {
      uploadingCertificate.value = false;
    }
  }

  Future<bool> complete(
    Calibration c, {
    required String performedAt,
    required String result,
    String? certificateNo,
    String? certificateFileId,
    String? findings,
    String? cost,
    num? cycleMonths,
    String? nextDueAt,
    String? agencyId,
    String? performerName,
  }) async {
    fieldErrors.clear();
    try {
      await repo.complete(
        c.id,
        performedAt: performedAt,
        result: result,
        certificateNo: certificateNo,
        certificateFileId: certificateFileId,
        findings: findings,
        cost: cost,
        cycleMonths: cycleMonths,
        nextDueAt: nextDueAt,
        agencyId: agencyId,
        performerName: performerName,
      );
      AppSnackbar.success('calibration.saved'.tr);
      await load();
      return true;
    } catch (e) {
      final apiError = ApiError.from(e);
      if (apiError.code == 'VALIDATION_ERROR') {
        fieldErrors.assignAll(apiError.fieldErrors());
      }
      AppSnackbar.error(e);
      return false;
    }
  }
}
