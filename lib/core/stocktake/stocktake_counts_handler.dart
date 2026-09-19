import '../../core/sync/outbox_service.dart';
import '../../data/repositories/stocktakes_repository.dart';
import 'stocktake_local_store.dart';

/// Handler outbox gửi batch counts kiểm kê (idempotent theo `clientId`).
class StocktakeCountsOutboxHandler implements OutboxHandler {
  StocktakeCountsOutboxHandler({required this.repo, required this.store});

  final StocktakesRepository repo;
  final StocktakeLocalStore store;

  static const typeName = 'stocktake_counts';

  @override
  String get type => typeName;

  @override
  Future<void> send(Map<String, dynamic> payload) async {
    final sessionId = payload['sessionId'] as String;
    final counts = (payload['counts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final extras = (payload['extras'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    if (counts.isNotEmpty) {
      final result = await repo.postCounts(sessionId, counts);
      await store.markSynced(sessionId, {
        ...result.accepted,
        ...result.duplicated,
      });
      await store.markConflicts(sessionId, {
        for (final c in result.conflicts) c.clientId: c.keptCountedAt,
      });
      // Extras mà server nhận từ counts (không có itemId) → đồng bộ theo clientId.
      await store.markExtrasSynced(sessionId, {
        ...result.extras,
        for (final e in extras)
          if (e['clientId'] is String) e['clientId'] as String,
      });
    }
    // Extras gửi kèm cũng đi trong `counts` (không itemId) theo hợp đồng C3.
  }
}
