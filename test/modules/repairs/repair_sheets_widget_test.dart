import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/core/widgets/detail_widgets.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/data/models/repair_detail.dart';
import 'package:labasset_mobile/data/repositories/catalogs_repository.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/modules/feature_pages.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class MockRepairs extends Mock implements RepairsRepository {}

class _Supplies extends Mock implements SuppliesRepository {}

class _Equipment extends Mock implements EquipmentRepository {}

class _Catalogs extends Mock implements CatalogsRepository {}

class _Outbox extends Mock implements OutboxService {
  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback(callback: () {});
}

/// Mở `/repairs/r1` (admin, phiếu đang sửa) với repo giả; trả repo.
Future<MockRepairs> openDetail(WidgetTester tester) async {
  final repairs = MockRepairs();
  when(() => repairs.detail('r1')).thenAnswer(
    (_) async => const RepairDetail(
      id: 'r1',
      code: 'SC-1',
      equipmentId: 'e1',
      status: 'in_progress',
      diagnosis: 'Chẩn đoán cũ',
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
  return repairs;
}

void main() {
  tearDown(Get.reset);

  testWidgets(
    'sheet Đổi trạng thái: lưu thành công → sheet đóng, không assertion',
    (tester) async {
      final repairs = await openDetail(tester);
      when(
        () => repairs.changeStatus('r1', any(), any()),
      ).thenAnswer((_) async {});

      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi trạng thái'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'ghi chú');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.tap(find.text('Xác nhận'));
      await tester.pump(const Duration(milliseconds: 50));
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      verify(
        () => repairs.changeStatus('r1', 'in_progress', 'ghi chú'),
      ).called(1);
      expect(find.text('Xác nhận'), findsNothing); // sheet đã đóng
      expect(find.text('Đã đổi trạng thái'), findsOneWidget); // toast
      expect(tester.takeException(), isNull);

      // Rời màn khi toast còn hiện: Get.back() không bị snackbar nuốt.
      Get.back();
      await tester.pumpAndSettle();
      expect(find.text('SC-1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sheet Chẩn đoán: API lỗi → sheet giữ nguyên', (tester) async {
    final repairs = await openDetail(tester);
    when(
      () => repairs.diagnose(
        'r1',
        diagnosis: any(named: 'diagnosis'),
        faultId: any(named: 'faultId'),
        faultGroupId: any(named: 'faultGroupId'),
        resolutionType: any(named: 'resolutionType'),
      ),
    ).thenThrow(Exception('boom'));

    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Chẩn đoán'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Chẩn đoán cũ'), findsOneWidget);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Lưu'), findsOneWidget); // vẫn mở
    expect(tester.takeException(), isNull);
    // Đóng bằng nút X của header.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Lưu'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'chi tiết phiếu cuộn toàn màn: header card ra khỏi màn, thanh tab còn ghim',
    (tester) async {
      tester.view.physicalSize = const Size(430, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await openDetail(tester);
      final header = find.byType(DetailHeaderCard);
      expect(header, findsOneWidget);
      expect(find.text('Tổng quan'), findsWidgets);

      await tester.drag(find.byType(NestedScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      // Header cuộn lên khỏi vùng nhìn (sliver ngoài viewport bị gỡ).
      expect(header, findsNothing);
      // Thanh tab vẫn hiện ngay dưới AppBar.
      final tabBar = find.byType(TabBar);
      expect(tabBar, findsOneWidget);
      expect(
        tester.getTopLeft(tabBar).dy,
        closeTo(tester.getBottomLeft(find.byType(AppBar)).dy + 9, 2),
      );
      // Thanh hành động dính đáy vẫn còn.
      expect(find.byType(StickyActionBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
