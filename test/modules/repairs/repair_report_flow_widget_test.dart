import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/core/widgets/detail_widgets.dart';
import 'package:labasset_mobile/data/models/equipment.dart';
import 'package:labasset_mobile/data/models/equipment_detail.dart';
import 'package:labasset_mobile/data/models/repair.dart';
import 'package:labasset_mobile/data/models/repair_detail.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/faults_repository.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/settings_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/data/repositories/tasks_repository.dart';
import 'package:labasset_mobile/modules/feature_pages.dart';
import 'package:labasset_mobile/modules/repairs/repair_form_controller.dart';
import 'package:labasset_mobile/modules/repairs/repair_form_view.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class MockRepairs extends Mock implements RepairsRepository {}

class MockEquipment extends Mock implements EquipmentRepository {}

class MockFaults extends Mock implements FaultsRepository {}

class MockAttachments extends Mock implements AttachmentService {}

class MockSettings extends Mock implements SettingsRepository {}

class MockTasks extends Mock implements TasksRepository {}

class MockSupplies extends Mock implements SuppliesRepository {}

class MockCatalogs extends Mock implements CatalogsRepository {}

class MockOutbox extends Mock implements OutboxService {
  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback(callback: () {});
}

const _created = RepairDetail(
  id: 'r-new',
  code: 'SC-NEW',
  equipmentId: 'e1',
  status: 'new',
);

/// Đăng ký repo giả cho luồng báo hỏng; trả repo sửa chữa.
MockRepairs registerFakes() {
  final repairs = MockRepairs();
  final equipment = MockEquipment();
  when(() => equipment.byId('e1')).thenAnswer(
    (_) async => const EquipmentSummary(
      id: 'e1',
      code: 'TB-01',
      name: 'Máy ly tâm',
      status: 'active',
    ),
  );
  when(() => equipment.detail('e1')).thenAnswer(
    (_) async => const EquipmentDetail(
      id: 'e1',
      code: 'TB-01',
      name: 'Máy ly tâm',
      status: 'active',
    ),
  );
  when(
    () => repairs.list(
      equipmentId: any(named: 'equipmentId'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) async => const RepairPage(items: [], total: 0));
  when(
    () => repairs.create(
      equipmentId: any(named: 'equipmentId'),
      description: any(named: 'description'),
      errorCode: any(named: 'errorCode'),
      severity: any(named: 'severity'),
      equipmentDown: any(named: 'equipmentDown'),
      faultId: any(named: 'faultId'),
    ),
  ).thenAnswer((_) async => _created);
  when(() => repairs.detail('r-new')).thenAnswer((_) async => _created);
  when(() => repairs.parts('r-new')).thenAnswer((_) async => const []);
  when(() => repairs.vendors('r-new')).thenAnswer((_) async => const []);
  when(() => repairs.costs('r-new')).thenAnswer((_) async => const []);
  final settings = MockSettings();
  when(settings.repairSla).thenAnswer((_) async => const {});
  final outbox = MockOutbox();
  when(outbox.items).thenAnswer((_) async => const []);

  final store = fakeStore()
    ..accessToken = 'A'
    ..user.value = fakeUser();
  Get.put(store);
  Get.put<RepairsRepository>(repairs);
  Get.put<EquipmentRepository>(equipment);
  Get.put<FaultsRepository>(MockFaults());
  Get.put<AttachmentService>(MockAttachments());
  Get.put<SettingsRepository>(settings);
  Get.put<TasksRepository>(MockTasks());
  Get.put<SuppliesRepository>(MockSupplies());
  Get.put<CatalogsRepository>(MockCatalogs());
  Get.put<OutboxService>(outbox);
  Get.put<KvCache>(FakeKvCache());
  return repairs;
}

void main() {
  tearDown(Get.reset);

  test('ảnh chụp lúc báo hỏng được gắn vào cùng phiếu khi thử lại', () async {
    final repairs = MockRepairs();
    final attachments = MockAttachments();
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(
      () => attachments.pickImageBytes(source: ImageSource.camera),
    ).thenAnswer(
      (_) async => (bytes: bytes, name: 'hong.jpg', mime: 'image/jpeg'),
    );
    when(
      () => repairs.create(
        equipmentId: 'e1',
        description: 'Máy hỏng',
        errorCode: null,
        severity: 'medium',
        equipmentDown: false,
        faultId: null,
      ),
    ).thenAnswer((_) async => _created);
    var attempts = 0;
    when(
      () => attachments.uploadBytes(
        entityType: 'repair_ticket',
        entityId: 'r-new',
        kind: 'photo',
        name: 'hong.jpg',
        mime: 'image/jpeg',
        bytes: bytes,
        label: 'Báo hỏng — hong.jpg',
      ),
    ).thenAnswer((_) async {
      if (++attempts == 1) throw Exception('upload failed');
      return const AttachmentUploadResult(AttachmentUploadStatus.uploaded);
    });
    String? opened;
    final c = RepairFormController(
      repairs: repairs,
      equipment: MockEquipment(),
      faults: MockFaults(),
      attachments: attachments,
      popWithId: (id) async {
        opened = id;
      },
    );
    c.equipmentRef.value = const EquipmentRef(
      id: 'e1',
      code: 'TB-01',
      name: 'Máy',
    );
    c.description.text = 'Máy hỏng';
    await c.addPhoto(source: ImageSource.camera);
    expect(c.photos.length, 1);
    expect(await c.submit(), false);
    expect(await c.submit(), true);
    expect(attempts, 2);
    expect(opened, 'r-new');
    verify(
      () => repairs.create(
        equipmentId: 'e1',
        description: 'Máy hỏng',
        errorCode: null,
        severity: 'medium',
        equipmentDown: false,
        faultId: null,
      ),
    ).called(1);
    c.onClose();
  });

  test('RepairFormController điền sẵn máy từ equipmentId', () async {
    final equipment = MockEquipment();
    when(() => equipment.byId('e1')).thenAnswer(
      (_) async => const EquipmentSummary(
        id: 'e1',
        code: 'TB-01',
        name: 'Máy ly tâm',
        status: 'active',
      ),
    );
    final c = RepairFormController(
      repairs: MockRepairs(),
      equipment: equipment,
      faults: MockFaults(),
      attachments: MockAttachments(),
      equipmentId: 'e1',
      popWithId: (_) async {},
    )..onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.equipmentRef.value?.code, 'TB-01');
    c.onClose();
  });

  testWidgets(
    'Báo hỏng từ hồ sơ máy: mở form máy điền sẵn, gửi → mở chi tiết phiếu mới',
    (tester) async {
      final repairs = registerFakes();
      await tester.pumpWidget(wrap(const SizedBox(), pages: featurePages()));
      await tester.pumpAndSettle();
      unawaited(Get.toNamed('/equipment/e1'));
      await tester.pumpAndSettle();

      // Nút chính dính đáy "Báo hỏng".
      await tester.tap(
        find.descendant(
          of: find.byType(StickyActionBar),
          matching: find.text('Báo hỏng'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RepairFormView), findsOneWidget);
      expect(find.text('TB-01 — Máy ly tâm'), findsOneWidget); // điền sẵn

      await tester.enterText(find.byType(TextField).first, 'Máy kêu to');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      verify(
        () => repairs.create(
          equipmentId: 'e1',
          description: 'Máy kêu to',
          errorCode: null,
          severity: 'medium',
          equipmentDown: false,
          faultId: null,
        ),
      ).called(1);
      // Form đã pop (toast không nuốt Get.back) — quay về hồ sơ máy.
      expect(find.byType(RepairFormView), findsNothing);
      expect(find.text('Đã tạo phiếu sửa chữa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tab Sửa chữa của máy: "Báo hỏng máy này" → form → chi tiết phiếu',
    (tester) async {
      registerFakes();
      await tester.pumpWidget(wrap(const SizedBox(), pages: featurePages()));
      await tester.pumpAndSettle();
      unawaited(Get.toNamed('/equipment/e1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sửa chữa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Báo hỏng máy này'));
      await tester.pumpAndSettle();
      expect(find.byType(RepairFormView), findsOneWidget);
      expect(find.text('TB-01 — Máy ly tâm'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Lỗi nguồn');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      // Trả id → mở chi tiết phiếu mới.
      expect(find.byType(RepairFormView), findsNothing);
      expect(find.text('SC-NEW'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Route /repairs/new (FAB Báo hỏng của tab Sửa chữa) mở form, không máy sẵn',
    (tester) async {
      registerFakes();
      await tester.pumpWidget(wrap(const SizedBox(), pages: featurePages()));
      await tester.pumpAndSettle();
      unawaited(Get.toNamed('/repairs/new'));
      await tester.pumpAndSettle();
      expect(find.byType(RepairFormView), findsOneWidget);
      expect(find.text('Chọn máy'), findsOneWidget);
      // Chưa chọn máy → lỗi tại chỗ, không gửi.
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(find.byType(RepairFormView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
