import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/data/models/department.dart';
import 'package:labasset_mobile/data/models/equipment_detail.dart';
import 'package:labasset_mobile/data/models/room.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/departments_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/modules/equipment/new_equipment_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockEquipment extends Mock implements EquipmentRepository {}

class _MockDepartments extends Mock implements DepartmentsRepository {}

class _MockCatalogs extends Mock implements CatalogsRepository {}

class _MockAttachments extends Mock implements AttachmentService {}

const _dept = DepartmentRef(id: 'd1', code: 'XN', name: 'Khoa Xét nghiệm');
const _room = RoomRef(
  id: 'r1',
  code: 'XN-P01',
  name: 'Phòng Huyết học',
  departmentId: 'd1',
);

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late _MockEquipment equipment;
  late _MockDepartments departments;
  late _MockCatalogs catalogs;
  late _MockAttachments attachments;
  late NewEquipmentController c;
  var popped = false;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    equipment = _MockEquipment();
    departments = _MockDepartments();
    catalogs = _MockCatalogs();
    attachments = _MockAttachments();
    popped = false;
    c = NewEquipmentController(
      equipment: equipment,
      departments: departments,
      catalogs: catalogs,
      attachments: attachments,
      pop: () => popped = true,
    );
  });

  tearDown(Get.reset);

  test('thiếu tên → lỗi, không gọi API', () async {
    expect(await c.submit(), isFalse);
    expect(c.error.value, 'Nhập tên máy');
    expect(c.fieldErrors['name'], isNotNull);
    verifyZeroInteractions(equipment);
  });

  test('thiếu khoa → lỗi field departmentId', () async {
    c.name.text = 'Máy';
    expect(await c.submit(), isFalse);
    expect(c.fieldErrors['departmentId'], isNotNull);
    verifyZeroInteractions(equipment);
  });

  test('thiếu phòng → lỗi field roomId, không gọi API', () async {
    c.name.text = 'Máy';
    c.setDepartment(_dept);
    expect(await c.submit(), isFalse);
    expect(c.fieldErrors['roomId'], 'Chọn phòng');
    verifyZeroInteractions(equipment);
  });

  test('chọn khoa → reset phòng', () async {
    c.setDepartment(_dept);
    c.room.value = _room;
    expect(c.room.value, isNotNull);
    c.setDepartment(
      const DepartmentRef(id: 'd2', code: 'CDHA', name: 'Khoa CĐHA'),
    );
    expect(c.room.value, isNull);
  });

  test('tạo phòng nhanh → được chọn luôn', () async {
    c.setDepartment(_dept);
    when(
      () => catalogs.createRoom(
        code: any(named: 'code'),
        name: any(named: 'name'),
        departmentId: any(named: 'departmentId'),
        building: any(named: 'building'),
        floor: any(named: 'floor'),
      ),
    ).thenAnswer((_) async => _room);
    final created = await c.quickCreateRoom(name: 'Phòng Huyết học');
    expect(created, isNotNull);
    expect(c.room.value?.id, 'r1');
    verify(
      () => catalogs.createRoom(
        code: null,
        name: 'Phòng Huyết học',
        departmentId: 'd1',
        building: null,
        floor: null,
      ),
    ).called(1);
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
    c.setDepartment(_dept);
    c.room.value = _room;
    c.handover = (
      bytes: Uint8List.fromList([1]),
      name: 'bb.jpg',
      mime: 'image/jpeg',
    );
    c.signature = Uint8List.fromList([2]);

    expect(await c.submit(), isTrue);
    expect(popped, isTrue);
    final captured =
        verify(() => equipment.create(captureAny())).captured.single
            as Map<String, dynamic>;
    expect(captured['departmentId'], 'd1');
    expect(captured['roomId'], 'r1');
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
    c.setDepartment(_dept);
    c.room.value = _room;
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
    c.setDepartment(_dept);
    c.room.value = _room;
    expect(await c.submit(), isFalse);
    expect(popped, isFalse);
  });
}
