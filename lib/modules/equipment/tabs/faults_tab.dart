import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/cache/kv_cache.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/equipment_extras.dart';
import '../../../data/repositories/faults_repository.dart';

/// Tab "Thư viện lỗi": lọc theo model máy + tìm mã lỗi/triệu chứng,
/// cache 24 giờ theo model để tra offline.
class FaultsTabController extends GetxController {
  FaultsTabController({
    required this.faults,
    required this.model,
    this.cache,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FaultsRepository faults;
  final String? model;
  final KvCache? cache;
  final DateTime Function() _now;

  static const cacheTtl = Duration(hours: 24);

  final RxList<FaultItem> items = <FaultItem>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxBool fromCache = false.obs;

  final search = TextEditingController();
  Timer? _debounce;

  String get cacheKey => 'faults.${model ?? 'all'}';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    fromCache.value = false;
    try {
      final page = await faults.list(
        model: model,
        q: search.text.trim(),
        limit: 50,
      );
      items.assignAll(page.items);
      await _saveCache(page.items);
    } catch (e) {
      final cached = await _readCache();
      if (cached != null && cached.isNotEmpty) {
        items.assignAll(cached);
        fromCache.value = true;
      } else {
        error.value = e;
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> _saveCache(List<FaultItem> list) async {
    try {
      await cache?.put(cacheKey, {
        'items': list.map((f) => f.toJson()).toList(),
      });
    } catch (_) {
      // best-effort
    }
  }

  Future<List<FaultItem>?> _readCache() async {
    try {
      final cached = await cache?.get(cacheKey);
      if (cached == null) return null;
      if (_now().difference(cached.updatedAt) > cacheTtl) return null;
      final raw = cached.value['items'];
      if (raw is! List) return null;
      return raw
          .whereType<Map>()
          .map((m) => FaultItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    search.dispose();
    super.onClose();
  }
}

class FaultsTab extends StatefulWidget {
  const FaultsTab({super.key, this.model});

  final String? model;

  @override
  State<FaultsTab> createState() => _FaultsTabState();
}

class _FaultsTabState extends State<FaultsTab> {
  late final FaultsTabController controller;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = widget.model ?? 'all';
    controller = FaultsTabController(
      faults: Get.find<FaultsRepository>(),
      model: widget.model,
      cache: Get.find(),
    );
    Get.put(controller, tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<FaultsTabController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: TextField(
            controller: controller.search,
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'equipment.faults.search'.tr,
            ),
          ),
        ),
        Obx(
          () => controller.fromCache.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 16,
                        color: context.status.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'equipment.faults.offline'.tr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) return const LoadingList();
            if (controller.error.value != null) {
              return ErrorState(
                error: controller.error.value!,
                onRetry: controller.load,
              );
            }
            if (controller.items.isEmpty) {
              return EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'equipment.faults.empty'.tr,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: controller.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final f = controller.items[i];
                return ListTile(
                  title: Text(
                    [
                      f.errorCode,
                      f.title,
                    ].where((s) => s.isNotEmpty).join(' — '),
                  ),
                  subtitle: Text(f.model),
                  trailing: StatusBadge(
                    tone: switch (f.severity) {
                      'critical' || 'high' => StatusTone.danger,
                      'medium' => StatusTone.warning,
                      _ => StatusTone.muted,
                    },
                    label: 'status.severity.${f.severity}'.tr,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
