import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/data/models/repair_detail.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/modules/feature_pages.dart';
import 'package:labasset_mobile/modules/repairs/tabs/parts_tab.dart';
import 'package:labasset_mobile/modules/repairs/tabs/vendors_tab.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _Repairs extends Mock implements RepairsRepository {}

class _Supplies extends Mock implements SuppliesRepository {}

class _Equipment extends Mock implements EquipmentRepository {}

class _Catalogs extends Mock implements CatalogsRepository {}

class _Outbox extends Mock implements OutboxService {
  // GetxService thật gọi các callback vòng đời khi Get.put → trả no-op.
  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback(callback: () {});
}

void main() {
  testWidgets(
    'chi tiết phiếu: tab Linh kiện/Thuê ngoài có controller, nhật ký và phân công hiện tên',
    (tester) async {
      final repairs = _Repairs();
      when(() => repairs.detail('r1')).thenAnswer(
        (_) async => const RepairDetail(
          id: 'r1',
          code: 'SC-1',
          equipmentId: 'e1',
          status: 'in_progress',
          assignee: RepairAssigneeRef(id: 'u9', fullName: 'Nguyễn Văn An'),
          assignments: [
            RepairAssignment(
              id: 'a1',
              userId: 'u9',
              role: 'primary',
              response: 'accepted',
            ),
          ],
          logs: [
            RepairLog(at: '2026-09-21T01:00:00Z', action: 'created'),
            RepairLog(
              at: '2026-09-21T02:00:00Z',
              action: 'status:in_progress',
              byUserId: 'u9',
            ),
          ],
        ),
      );
      when(() => repairs.parts('r1')).thenAnswer((_) async => const []);
      when(() => repairs.vendors('r1')).thenAnswer((_) async => const []);
      when(() => repairs.costs('r1')).thenAnswer((_) async => const []);
      final outbox = _Outbox();
      when(outbox.items).thenAnswer((_) async => const []);

      final store = fakeStore()
        ..accessToken = 'A'
        ..user.value = fakeUser();
      Get.put(store);
      Get.put<RepairsRepository>(repairs);
      Get.put<SuppliesRepository>(_Supplies());
      Get.put<EquipmentRepository>(_Equipment());
      Get.put<CatalogsRepository>(_Catalogs());
      Get.put<OutboxService>(outbox);
      Get.put<KvCache>(FakeKvCache());

      await tester.pumpWidget(wrap(const SizedBox(), pages: featurePages()));
      await tester.pumpAndSettle();
      unawaited(Get.toNamed('/repairs/r1'));
      await tester.pumpAndSettle();

      // Phân công hiện tên thay vì UUID.
      expect(find.text('Nguyễn Văn An'), findsWidgets);
      expect(find.text('u9'), findsNothing);

      // Nhật ký: enum → tiếng Việt.
      await tester.tap(find.text('Nhật ký'));
      await tester.pumpAndSettle();
      expect(find.text('Tạo phiếu'), findsOneWidget);
      expect(find.text('Đổi trạng thái → Đang sửa'), findsOneWidget);
      expect(find.text('status:in_progress'), findsNothing);

      // Tab phụ có controller (trước đây đỏ màn "not found").
      await tester.tap(find.text('Linh kiện/vật tư'));
      await tester.pumpAndSettle();
      expect(find.byType(PartsTab), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Thuê ngoài'));
      await tester.pumpAndSettle();
      expect(find.byType(VendorsTab), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
