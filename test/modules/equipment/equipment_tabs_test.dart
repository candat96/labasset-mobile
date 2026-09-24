import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/equipment_parts.dart';
import 'package:labasset_mobile/data/models/repair_detail.dart';
import 'package:labasset_mobile/data/repositories/faults_repository.dart';
import 'package:labasset_mobile/modules/equipment/tabs/faults_tab.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockFaults extends Mock implements FaultsRepository {}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  tearDown(Get.reset);

  group('EquipmentComponent.usedPct', () {
    test('tính theo giờ chạy', () {
      const c = EquipmentComponent(
        id: 'c1',
        name: 'Bơm',
        lifespanHours: 1000,
        usageHoursAtInstall: '100',
      );
      final pct = c.usedPct(currentRunHours: '600');
      expect(pct, closeTo(0.5, 0.0001));
    });

    test('tính theo test count', () {
      const c = EquipmentComponent(
        id: 'c1',
        name: 'Bơm',
        lifespanTests: 100,
        usageTestsAtInstall: 20,
      );
      expect(c.usedPct(currentTestCount: 80), closeTo(0.6, 0.0001));
    });

    test('lấy giá trị lớn nhất trong các nguồn', () {
      const c = EquipmentComponent(
        id: 'c1',
        name: 'Bơm',
        lifespanHours: 1000,
        usageHoursAtInstall: '0',
        lifespanTests: 10,
        usageTestsAtInstall: 0,
      );
      expect(
        c.usedPct(currentRunHours: '100', currentTestCount: 9),
        closeTo(0.9, 0.0001),
      );
    });

    test('thiếu dữ liệu → null', () {
      const c = EquipmentComponent(id: 'c1', name: 'Bơm');
      expect(c.usedPct(currentRunHours: '10'), isNull);
    });
  });

  group('FaultsTabController', () {
    test('load lỗi thường gặp theo máy + lưu cache 24h', () async {
      final faults = _MockFaults();
      final cache = FakeKvCache();
      when(
        () => faults.suggest(
          equipmentId: 'e1',
          q: any(named: 'q'),
        ),
      ).thenAnswer(
        (_) async => const [
          FaultSuggestionMatch(
            fault: SuggestedFault(
              id: 'f1',
              title: 'Lỗi cảm biến',
              errorCode: 'E-01',
              severity: 'high',
            ),
            onEquipment: 2,
            sameModel: 3,
          ),
        ],
      );
      final c = FaultsTabController(
        faults: faults,
        equipmentId: 'e1',
        cache: cache,
      );
      await c.load();
      expect(c.items.single.fault.errorCode, 'E-01');
      expect(c.items.single.onEquipment, 2);
      expect(c.fromCache.value, isFalse);
      expect(cache.store.containsKey('faults.eq.e1'), isTrue);
    });

    test('mất mạng → dùng cache trong 24h', () async {
      final faults = _MockFaults();
      final cache = FakeKvCache();
      await cache.put('faults.eq.e1', {
        'items': [
          {
            'fault': {
              'id': 'f1',
              'title': 'Lỗi cảm biến',
              'errorCode': 'E-01',
              'severity': 'high',
            },
            'occurrences': {'onEquipment': 1, 'sameModel': 0},
          },
        ],
      });
      when(
        () => faults.suggest(
          equipmentId: any(named: 'equipmentId'),
          q: any(named: 'q'),
        ),
      ).thenThrow(Exception('offline'));
      final c = FaultsTabController(
        faults: faults,
        equipmentId: 'e1',
        cache: cache,
      );
      await c.load();
      expect(c.fromCache.value, isTrue);
      expect(c.items.single.fault.errorCode, 'E-01');
      expect(c.error.value, isNull);
    });

    test('cache quá 24h → báo lỗi', () async {
      final faults = _MockFaults();
      final cache = FakeKvCache();
      await cache.put('faults.eq.e1', {'items': <dynamic>[]});
      when(
        () => faults.suggest(
          equipmentId: any(named: 'equipmentId'),
          q: any(named: 'q'),
        ),
      ).thenThrow(Exception('offline'));
      final c = FaultsTabController(
        faults: faults,
        equipmentId: 'e1',
        cache: cache,
        now: () => DateTime.now().add(const Duration(hours: 25)),
      );
      await c.load();
      expect(c.error.value, isNotNull);
      expect(c.fromCache.value, isFalse);
    });
  });
}
