import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';

import '../../../core/cache/kv_cache.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_list.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/repair_detail.dart';
import '../../../data/repositories/faults_repository.dart';

/// Tab "Thư viện lỗi": lỗi thường gặp của **máy đang xem** (theo model/nhóm/hãng
/// qua `/v1/faults/suggest`), tìm mã lỗi/triệu chứng, cache 24 giờ để tra offline.
class FaultsTabController extends GetxController {
  FaultsTabController({
    required this.faults,
    required this.equipmentId,
    this.cache,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FaultsRepository faults;
  final String equipmentId;
  final KvCache? cache;
  final DateTime Function() _now;

  static const cacheTtl = Duration(hours: 24);

  final RxList<FaultSuggestionMatch> items = <FaultSuggestionMatch>[].obs;
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();
  final RxBool fromCache = false.obs;

  final search = TextEditingController();
  Timer? _debounce;

  String get cacheKey => 'faults.eq.$equipmentId';

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
      final list = await faults.suggest(
        equipmentId: equipmentId,
        q: search.text.trim(),
      );
      items.assignAll(list);
      await _saveCache(list);
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

  Future<void> _saveCache(List<FaultSuggestionMatch> list) async {
    try {
      await cache?.put(cacheKey, {
        'items': [
          for (final m in list)
            {
              'fault': m.fault.toJson(),
              'occurrences': {
                'onEquipment': m.onEquipment,
                'sameModel': m.sameModel,
              },
            },
        ],
      });
    } catch (_) {
      // best-effort
    }
  }

  Future<List<FaultSuggestionMatch>?> _readCache() async {
    try {
      final cached = await cache?.get(cacheKey);
      if (cached == null) return null;
      if (_now().difference(cached.updatedAt) > cacheTtl) return null;
      final raw = cached.value['items'];
      if (raw is! List) return null;
      return raw
          .whereType<Map>()
          .map(
            (m) => FaultSuggestionMatch.fromJson(Map<String, dynamic>.from(m)),
          )
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
  const FaultsTab({super.key, required this.equipmentId});

  final String equipmentId;

  @override
  State<FaultsTab> createState() => _FaultsTabState();
}

class _FaultsTabState extends State<FaultsTab> {
  late final FaultsTabController controller;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = widget.equipmentId;
    controller = FaultsTabController(
      faults: Get.find<FaultsRepository>(),
      equipmentId: widget.equipmentId,
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
              prefixIcon: const Icon(LucideIcons.search),
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
                        LucideIcons.cloudOff,
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
                icon: LucideIcons.bookOpen,
                title: 'equipment.faults.empty'.tr,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: controller.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = controller.items[i];
                final f = m.fault;
                return ListTile(
                  title: Text(
                    [
                      f.errorCode,
                      f.title,
                    ].where((s) => s.isNotEmpty).join(' — '),
                  ),
                  subtitle: Text(
                    'equipment.faults.times'.trParams({
                      'on': '${m.onEquipment}',
                      'model': '${m.sameModel}',
                    }),
                  ),
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
