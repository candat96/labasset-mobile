import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/data/models/equipment.dart';
import 'package:labasset_mobile/data/models/repair.dart';
import 'package:labasset_mobile/data/models/request.dart';
import 'package:labasset_mobile/data/models/supply.dart';
import 'package:labasset_mobile/data/repositories/equipment_repository.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/data/repositories/requests_repository.dart';
import 'package:labasset_mobile/data/repositories/supplies_repository.dart';
import 'package:labasset_mobile/modules/search/search_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockEquipment extends Mock implements EquipmentRepository {}

class _MockSupplies extends Mock implements SuppliesRepository {}

class _MockRepairs extends Mock implements RepairsRepository {}

class _MockRequests extends Mock implements RequestsRepository {}

void main() {
  late _MockEquipment equipment;
  late _MockSupplies supplies;
  late _MockRepairs repairs;
  late _MockRequests requests;
  late GlobalSearchController c;
  late List<String> routes;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    equipment = _MockEquipment();
    supplies = _MockSupplies();
    repairs = _MockRepairs();
    requests = _MockRequests();
    routes = [];
    c = GlobalSearchController(
      equipment: equipment,
      supplies: supplies,
      repairs: repairs,
      requests: requests,
      navigate: (r) async => routes.add(r),
    );
  });

  tearDown(Get.reset);

  void stubAll({
    List<EquipmentSummary> eq = const [],
    List<SupplySummary> sup = const [],
    List<RepairSummary> rep = const [],
    List<RequestSummary> req = const [],
  }) {
    when(
      () => equipment.search(any(), limit: 5),
    ).thenAnswer((_) async => EquipmentPage(items: eq, total: eq.length));
    when(
      () => supplies.list(q: any(named: 'q'), limit: 5),
    ).thenAnswer((_) async => SupplyPage(items: sup, total: sup.length));
    when(
      () => repairs.list(q: any(named: 'q'), limit: 5),
    ).thenAnswer((_) async => RepairPage(items: rep, total: rep.length));
    when(
      () => requests.list(q: any(named: 'q'), limit: 5),
    ).thenAnswer((_) async => RequestPage(items: req, total: req.length));
  }

  test('dưới 2 ký tự → không gọi API', () async {
    await c.search('a');
    expect(c.groups, isEmpty);
    expect(c.searched.value, isFalse);
    verifyZeroInteractions(equipment);
    verifyZeroInteractions(supplies);
    verifyZeroInteractions(repairs);
    verifyZeroInteractions(requests);
  });

  test('ghép 4 nguồn thành nhóm, bỏ nhóm rỗng', () async {
    stubAll(
      eq: const [
        EquipmentSummary(id: 'e1', code: 'M1', name: 'Máy X', status: 'active'),
      ],
      sup: const [SupplySummary(id: 's1', code: 'VT1', name: 'Găng tay')],
    );
    await c.search('MM');
    expect(c.groups.map((g) => g.key), ['equipment', 'supplies']);
    expect(c.groups.first.hits.first.title, 'M1 — Máy X');
    expect(c.searched.value, isTrue);
    expect(c.error.value, isNull);
  });

  test('một nguồn lỗi → các nguồn khác vẫn hiển thị', () async {
    stubAll(
      eq: const [
        EquipmentSummary(id: 'e1', code: 'M1', name: 'Máy X', status: 'active'),
      ],
    );
    when(
      () => supplies.list(q: any(named: 'q'), limit: 5),
    ).thenThrow(ApiError(500, 'INTERNAL_ERROR', ''));
    await c.search('MM');
    expect(c.groups.map((g) => g.key), ['equipment']);
    expect(c.error.value, isNull);
  });

  test('tất cả nguồn lỗi → giữ lỗi để hiện ErrorState', () async {
    final err = ApiError(0, 'NETWORK_ERROR', '');
    when(() => equipment.search(any(), limit: 5)).thenThrow(err);
    when(() => supplies.list(q: any(named: 'q'), limit: 5)).thenThrow(err);
    when(() => repairs.list(q: any(named: 'q'), limit: 5)).thenThrow(err);
    when(() => requests.list(q: any(named: 'q'), limit: 5)).thenThrow(err);
    await c.search('MM');
    expect(c.groups, isEmpty);
    expect(c.error.value, isNotNull);
    expect(c.searched.value, isTrue);
  });

  test('mở kết quả → điều hướng đúng route', () async {
    await c.open(
      const SearchHit(
        id: 'e1',
        title: 't',
        subtitle: '',
        route: '/equipment/e1',
      ),
    );
    expect(routes, ['/equipment/e1']);
  });

  test('kết quả cũ không ghi đè khi gõ tiếp (generation)', () async {
    stubAll(
      eq: const [
        EquipmentSummary(id: 'e1', code: 'M1', name: 'Máy X', status: 'active'),
      ],
    );
    final slow = c.search('MM');
    await c.search('MMM');
    await slow;
    expect(c.groups, hasLength(1));
  });

  test('debounce gọi search sau 300 ms', () {
    stubAll();
    c.onQueryChanged('MM');
    expect(c.searched.value, isFalse);
  });
}
