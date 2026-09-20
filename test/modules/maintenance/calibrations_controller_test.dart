import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/data/models/maintenance.dart';
import 'package:labasset_mobile/data/repositories/calibrations_repository.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/modules/maintenance/calibrations_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalibrations extends Mock implements CalibrationsRepository {}

class _MockCatalogs extends Mock implements CatalogsRepository {}

class _MockAttachments extends Mock implements AttachmentService {}

void main() {
  late _MockCalibrations repo;
  late CalibrationsController c;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockCalibrations();
    when(
      () => repo.list(
        equipmentId: any(named: 'equipmentId'),
        status: any(named: 'status'),
        result: any(named: 'result'),
        dueBefore: any(named: 'dueBefore'),
        type: any(named: 'type'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const CalibrationPage(
        items: [
          Calibration(
            id: 'c1',
            code: 'KD-1',
            equipmentId: 'e1',
            scheduledAt: '2026-10-01T00:00:00Z',
            status: 'scheduled',
          ),
        ],
        total: 1,
      ),
    );
    c = CalibrationsController(
      repo: repo,
      catalogs: _MockCatalogs(),
      attachments: _MockAttachments(),
      userId: 'u1',
    );
  });

  tearDown(Get.reset);

  test('load danh sách', () async {
    await c.load();
    expect(c.items.single.code, 'KD-1');
    expect(c.total.value, 1);
  });

  test('preset đến hạn 30 ngày truyền dueBefore', () async {
    await c.load();
    c.setPreset(dueSoon: true);
    await Future<void>.delayed(Duration.zero);
    verify(
      () => repo.list(
        equipmentId: any(named: 'equipmentId'),
        status: any(named: 'status'),
        result: any(named: 'result'),
        dueBefore: any(named: 'dueBefore'),
        type: any(named: 'type'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).called(greaterThan(1));
    expect(c.dueSoonOnly.value, isTrue);
  });

  test('complete gửi kết quả + reload', () async {
    when(
      () => repo.complete(
        'c1',
        performedAt: any(named: 'performedAt'),
        result: any(named: 'result'),
        certificateNo: any(named: 'certificateNo'),
        certificateFileId: any(named: 'certificateFileId'),
        findings: any(named: 'findings'),
        cost: any(named: 'cost'),
        cycleMonths: any(named: 'cycleMonths'),
        nextDueAt: any(named: 'nextDueAt'),
        agencyId: any(named: 'agencyId'),
        performerName: any(named: 'performerName'),
      ),
    ).thenAnswer((_) async {});
    await c.load();
    final ok = await c.complete(
      c.items.single,
      performedAt: '2026-09-19',
      result: 'pass',
      certificateNo: 'CN-1',
      certificateFileId: 'file-1',
      agencyId: 'agency-1',
      findings: 'Đủ điều kiện',
      cost: '1500000',
      cycleMonths: 12,
      nextDueAt: '2027-09-19',
    );
    expect(ok, isTrue);
    verify(
      () => repo.complete(
        'c1',
        performedAt: '2026-09-19',
        result: 'pass',
        certificateNo: 'CN-1',
        certificateFileId: 'file-1',
        findings: 'Đủ điều kiện',
        cost: '1500000',
        cycleMonths: 12,
        nextDueAt: '2027-09-19',
        agencyId: 'agency-1',
        performerName: null,
      ),
    ).called(1);
  });

  test('complete lỗi → false', () async {
    when(
      () => repo.complete(
        any(),
        performedAt: any(named: 'performedAt'),
        result: any(named: 'result'),
        certificateNo: any(named: 'certificateNo'),
        certificateFileId: any(named: 'certificateFileId'),
        findings: any(named: 'findings'),
        cost: any(named: 'cost'),
        cycleMonths: any(named: 'cycleMonths'),
        nextDueAt: any(named: 'nextDueAt'),
        agencyId: any(named: 'agencyId'),
        performerName: any(named: 'performerName'),
      ),
    ).thenThrow(Exception('boom'));
    await c.load();
    expect(
      await c.complete(c.items.single, performedAt: 'x', result: 'fail'),
      isFalse,
    );
  });

  test('VALIDATION_ERROR gắn lỗi theo field', () async {
    when(
      () => repo.complete(
        any(),
        performedAt: any(named: 'performedAt'),
        result: any(named: 'result'),
        certificateNo: any(named: 'certificateNo'),
        certificateFileId: any(named: 'certificateFileId'),
        findings: any(named: 'findings'),
        cost: any(named: 'cost'),
        cycleMonths: any(named: 'cycleMonths'),
        nextDueAt: any(named: 'nextDueAt'),
        agencyId: any(named: 'agencyId'),
        performerName: any(named: 'performerName'),
      ),
    ).thenThrow(
      ApiError(400, 'VALIDATION_ERROR', '', {
        'certificateNo': 'Số chứng nhận không hợp lệ',
      }),
    );
    await c.load();
    final ok = await c.complete(
      c.items.single,
      performedAt: '2026-09-19',
      result: 'pass',
    );
    expect(ok, isFalse);
    expect(c.fieldErrors['certificateNo'], 'Số chứng nhận không hợp lệ');
  });
}
