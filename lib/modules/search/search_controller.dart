import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/repairs_repository.dart';
import '../../data/repositories/requests_repository.dart';
import '../../data/repositories/supplies_repository.dart';

/// Một kết quả tìm kiếm đã chuẩn hoá để hiển thị/điều hướng.
class SearchHit {
  const SearchHit({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String id;
  final String title;
  final String subtitle;
  final String route;
}

/// Nhóm kết quả theo nguồn: equipment | supplies | repairs | requests.
class SearchGroup {
  const SearchGroup({required this.key, required this.hits});

  final String key;
  final List<SearchHit> hits;
}

/// Tìm kiếm toàn cục: gọi song song 4 nguồn `?q&limit=5`, debounce 300 ms.
class GlobalSearchController extends GetxController {
  GlobalSearchController({
    required this.equipment,
    required this.supplies,
    required this.repairs,
    required this.requests,
    Future<void> Function(String route)? navigate,
    this.debounce = const Duration(milliseconds: 300),
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r));

  final EquipmentRepository equipment;
  final SuppliesRepository supplies;
  final RepairsRepository repairs;
  final RequestsRepository requests;
  final Future<void> Function(String route) _navigate;
  final Duration debounce;

  final query = TextEditingController();
  final RxList<SearchGroup> groups = <SearchGroup>[].obs;
  final RxBool loading = false.obs;
  final RxBool searched = false.obs;
  final Rxn<Object> error = Rxn<Object>();

  Timer? _timer;
  int _generation = 0;

  void onQueryChanged(String value) {
    _timer?.cancel();
    _timer = Timer(debounce, () => search(value));
  }

  Future<void> search(String raw) async {
    final term = raw.trim();
    final gen = ++_generation;
    if (term.length < 2) {
      groups.clear();
      searched.value = false;
      loading.value = false;
      error.value = null;
      return;
    }
    loading.value = true;
    error.value = null;
    final results = await Future.wait([
      _guard(() => _searchEquipment(term)),
      _guard(() => _searchSupplies(term)),
      _guard(() => _searchRepairs(term)),
      _guard(() => _searchRequests(term)),
    ]);
    if (gen != _generation) return;
    final found = results.whereType<SearchGroup>().toList();
    groups.assignAll(found.where((g) => g.hits.isNotEmpty));
    error.value = found.isEmpty
        ? results.firstWhere((r) => r is! SearchGroup, orElse: () => null)
        : null;
    searched.value = true;
    loading.value = false;
  }

  Future<Object?> _guard(Future<SearchGroup> Function() run) async {
    try {
      return await run();
    } catch (e) {
      return e; // nguồn lỗi → bỏ qua, không chặn nguồn khác
    }
  }

  Future<SearchGroup> _searchEquipment(String q) async {
    final page = await equipment.search(q, limit: 5);
    return SearchGroup(
      key: 'equipment',
      hits: [
        for (final e in page.items)
          SearchHit(
            id: e.id,
            title: '${e.code} — ${e.name}',
            subtitle: [
              e.departmentLabel,
              e.groupLabel,
            ].whereType<String>().join(' · '),
            route: Routes.equipment(e.id),
          ),
      ],
    );
  }

  Future<SearchGroup> _searchSupplies(String q) async {
    final page = await supplies.list(q: q, limit: 5);
    return SearchGroup(
      key: 'supplies',
      hits: [
        for (final s in page.items)
          SearchHit(
            id: s.id,
            title: '${s.code} — ${s.name}',
            subtitle: s.isActive ? '' : 'status.inactive'.tr,
            route: Routes.supply(s.id),
          ),
      ],
    );
  }

  Future<SearchGroup> _searchRepairs(String q) async {
    final page = await repairs.list(q: q, limit: 5);
    return SearchGroup(
      key: 'repairs',
      hits: [
        for (final r in page.items)
          SearchHit(
            id: r.id,
            title: '${r.code} — ${r.equipmentLabel}',
            subtitle: 'status.repair.${r.status}'.tr,
            route: Routes.repair(r.id),
          ),
      ],
    );
  }

  Future<SearchGroup> _searchRequests(String q) async {
    final page = await requests.list(q: q, limit: 5);
    return SearchGroup(
      key: 'requests',
      hits: [
        for (final r in page.items)
          SearchHit(
            id: r.id,
            title: '${r.code} — ${r.reason}',
            subtitle: 'status.request.${r.status}'.tr,
            route: Routes.request(r.id),
          ),
      ],
    );
  }

  Future<void> open(SearchHit hit) => _navigate(hit.route);

  @override
  void onClose() {
    _timer?.cancel();
    query.dispose();
    super.onClose();
  }
}
