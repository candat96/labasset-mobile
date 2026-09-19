import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/data/models/equipment_detail.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/faults_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/data/repositories/tasks_repository.dart';
import 'package:labasset_mobile/modules/feature_pages.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockEquipment extends Mock implements EquipmentRepository {}

class _MockTasks extends Mock implements TasksRepository {}

class _MockSupplies extends Mock implements SuppliesRepository {}

class _MockFaults extends Mock implements FaultsRepository {}

void main() {
  testWidgets('hồ sơ máy: thẻ tóm tắt + tab hiển thị', (tester) async {
    final equipment = _MockEquipment();
    when(() => equipment.detail('e1')).thenAnswer(
      (_) async => const EquipmentDetail(
        id: 'e1',
        code: 'TB-01',
        name: 'Máy ly tâm',
        status: 'active',
        model: '5702',
        serial: 'SN-1',
        location: 'Khoa XN',
        currentRunHours: '120.5',
        counts: EquipmentCounts(
          accessories: 2,
          componentsDue: 1,
          openRepairs: 0,
        ),
      ),
    );

    final store = fakeStore()
      ..accessToken = 'A'
      ..user.value = fakeUser();
    Get.put(store);
    Get.put<EquipmentRepository>(equipment);
    Get.put<TasksRepository>(_MockTasks());
    Get.put<SuppliesRepository>(_MockSupplies());
    Get.put<FaultsRepository>(_MockFaults());
    Get.put<KvCache>(FakeKvCache());

    await tester.pumpWidget(wrap(const SizedBox(), pages: featurePages()));
    await tester.pumpAndSettle();

    unawaited(Get.toNamed('/equipment/e1'));
    await tester.pumpAndSettle();

    expect(find.text('Máy ly tâm'), findsOneWidget);
    expect(find.text('Hoạt động'), findsOneWidget);
    expect(find.text('TB-01'), findsWidgets);
    expect(find.text('Thông số'), findsWidgets);
    expect(find.text('Timeline'), findsOneWidget);
    // Thao tác nhanh (các chip đầu hiển thị trong dải cuộn ngang)
    expect(find.text('Báo hỏng'), findsOneWidget);
    expect(find.text('Bảo dưỡng đột xuất'), findsOneWidget);
    expect(find.text('Xuất vật tư'), findsOneWidget);
  });
}
