import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../data/models/global_search.dart';
import '../../data/repositories/search_repository.dart';

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

class SearchGroup {
  const SearchGroup({required this.key, required this.hits});
  final String key;
  final List<SearchHit> hits;
}

/// Tìm kiếm toàn cục bằng một call `/v1/search`, debounce 300 ms.
class GlobalSearchController extends GetxController {
  GlobalSearchController({
    required this.repository,
    Future<void> Function(String route)? navigate,
    this.debounce = const Duration(milliseconds: 300),
  }) : _navigate = navigate ?? ((r) async => Get.toNamed(r));

  final SearchRepository repository;
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
    try {
      final result = await repository.search(term, limit: 5);
      if (gen != _generation) return;
      groups.assignAll(
        [
          _group('equipment', result.equipment),
          _group('supplies', result.supplies),
          _group('repairs', result.repairs),
          _group('requests', result.requests),
          _group('faults', result.faults),
        ].where((group) => group.hits.isNotEmpty),
      );
      searched.value = true;
    } catch (e) {
      if (gen != _generation) return;
      groups.clear();
      error.value = e;
      searched.value = true;
    } finally {
      if (gen == _generation) loading.value = false;
    }
  }

  SearchGroup _group(String key, List<GlobalSearchHit> values) => SearchGroup(
    key: key,
    hits: [
      for (final hit in values)
        SearchHit(
          id: hit.id,
          title: hit.code.isEmpty ? hit.title : '${hit.code} — ${hit.title}',
          subtitle: hit.subtitle,
          route: key == 'faults' ? Routes.placeholderFor('faults') : hit.link,
        ),
    ],
  );

  Future<void> open(SearchHit hit) => _navigate(hit.route);

  @override
  void onClose() {
    _timer?.cancel();
    query.dispose();
    super.onClose();
  }
}
