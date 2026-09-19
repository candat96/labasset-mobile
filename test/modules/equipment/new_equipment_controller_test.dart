import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/data/models/equipment_detail.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/modules/equipment/new_equipment_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockEquipment extends Mock implements EquipmentRepository {}

class _MockDepartments extends Mock implements DepartmentsRepository {}

class _MockAttachments extends Mock implements AttachmentService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late _MockEquipment equipment;
  late _MockDepartments departments;
  late _MockAttachments attachments;
  late NewEquipmentController c;
  var popped = false;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    equipment = _MockEquipment();
    departments = _MockDepartments();
    attachments = _MockAttachments();
    popped = false;
    c = NewEquipmentController(
      equipment: equipment,
      departments: departments,
      attachments: attachments,
      pop: () => popped = true,
    );
  });

  tearDown(Get.reset);

  test('thiếu tên → lỗi, không gọi API', () async {
    expect(await c.submit(), isFalse);
    expect(c.error.value, 'Nhập tên máy');
    verifyZeroInteractions(equipment);
  });

  test('tạo máy + upload biên bản/chữ ký, rồi đóng màn', () async {
    when(() => equipment.create(any())).thenAnswer(
      (_) async => const EquipmentDetail(
        id: 'e1',
        code: 'TB-1',
        name: 'Máy',
        status: 'active',
      ),
    );
    when(
      () => attachments.uploadBytes(
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        kind: any(named: 'kind'),
        name: any(named: 'name'),
        mime: any(named: 'mime'),
        bytes: any(named: 'bytes'),
        label: any(named: 'label'),
      ),
    ).thenAnswer(
      (_) async =>
          const AttachmentUploadResult(AttachmentUploadStatus.uploaded),
    );
    c.name.text = 'Máy ly tâm';
    c.model.text = '5702';
    c.serial.text = 'SN1';
    c.handover = (
      bytes: Uint8List.fromList([1]),
      name: 'bb.jpg',
      mime: 'image/jpeg',
    );
    c.signature = Uint8List.fromList([2]);

    expect(await c.submit(), isTrue);
    expect(popped, isTrue);
    verify(() => equipment.create(any())).called(1);
    verify(
      () => attachments.uploadBytes(
        entityType: 'equipment',
        entityId: 'e1',
        kind: 'handover',
        name: any(named: 'name'),
        mime: any(named: 'mime'),
        bytes: any(named: 'bytes'),
        label: any(named: 'label'),
      ),
    ).called(2);
  });

  test('upload lỗi không chặn tạo máy', () async {
    when(() => equipment.create(any())).thenAnswer(
      (_) async => const EquipmentDetail(
        id: 'e1',
        code: 'TB-1',
        name: 'Máy',
        status: 'active',
      ),
    );
    when(
      () => attachments.uploadBytes(
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        kind: any(named: 'kind'),
        name: any(named: 'name'),
        mime: any(named: 'mime'),
        bytes: any(named: 'bytes'),
        label: any(named: 'label'),
      ),
    ).thenThrow(Exception('boom'));
    c.name.text = 'Máy';
    c.handover = (
      bytes: Uint8List.fromList([1]),
      name: 'bb.jpg',
      mime: 'image/jpeg',
    );
    expect(await c.submit(), isTrue);
    expect(popped, isTrue);
  });

  test('API lỗi → trả false, giữ màn', () async {
    when(() => equipment.create(any())).thenThrow(Exception('boom'));
    c.name.text = 'Máy';
    expect(await c.submit(), isFalse);
    expect(popped, isFalse);
  });
}
