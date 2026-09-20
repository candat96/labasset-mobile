import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/core/stocktake/stocktake_counts_handler.dart';
import 'package:labasset_mobile/core/stocktake/stocktake_local_store.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/data/models/stocktake.dart';
import 'package:labasset_mobile/data/repositories/stocktakes_repository.dart';
import 'package:labasset_mobile/data/repositories/files_repository.dart';
import 'package:labasset_mobile/modules/stocktake/stocktake_count_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements StocktakesRepository {}

class _MockOutbox extends Mock implements OutboxService {}

class _MockAttachments extends Mock implements AttachmentService {}

class _MockFiles extends Mock implements FilesRepository {}

/// Store in-memory cho test (không cần sqflite).
class _FakeStore implements StocktakeLocalStore {
  final Map<String, List<StocktakeLocalItem>> rowsBySession = {};
  final Map<String, List<StocktakeLocalExtra>> extrasBySession = {};
  final Map<String, StocktakeLocalMeta> metas = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> savePackage({
    required String sessionId,
    required String code,
    required String name,
    required String type,
    String? etag,
    required List<StocktakeLocalItem> items,
  }) async {
    rowsBySession[sessionId] = List.of(items);
    metas[sessionId] = StocktakeLocalMeta(
      sessionId: sessionId,
      code: code,
      name: name,
      type: type,
      etag: etag,
      downloadedAt: DateTime(2026, 9, 20),
    );
  }

  @override
  Future<StocktakeLocalMeta?> meta(String sessionId) async => metas[sessionId];

  @override
  Future<List<StocktakeLocalItem>> items(String sessionId) async =>
      rowsBySession[sessionId] ?? [];

  @override
  Future<void> upsertCount(StocktakeLocalItem item) async {
    final list = rowsBySession[item.sessionId] ?? [];
    final i = list.indexWhere((e) => e.itemId == item.itemId);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
  }

  @override
  Future<List<StocktakeLocalExtra>> extras(String sessionId) async =>
      extrasBySession[sessionId] ?? [];

  @override
  Future<void> addExtra(StocktakeLocalExtra extra) async {
    extrasBySession.putIfAbsent(extra.sessionId, () => []).add(extra);
  }

  @override
  Future<int> pendingCount(String sessionId) async {
    final it = (rowsBySession[sessionId] ?? [])
        .where((e) => e.counted && !e.synced && !e.conflict)
        .length;
    final ex = (extrasBySession[sessionId] ?? [])
        .where((e) => !e.synced)
        .length;
    return it + ex;
  }

  @override
  Future<void> markSynced(String sessionId, Set<String> clientIds) async {
    for (final e in rowsBySession[sessionId] ?? []) {
      if (clientIds.contains(e.clientId)) e.synced = true;
    }
  }

  @override
  Future<void> markConflicts(
    String sessionId,
    Map<String, String?> keptAtByClientId,
  ) async {
    for (final e in rowsBySession[sessionId] ?? []) {
      if (keptAtByClientId.containsKey(e.clientId)) {
        e.conflict = true;
        e.keptCountedAt = keptAtByClientId[e.clientId];
      }
    }
  }

  @override
  Future<void> markExtrasSynced(String sessionId, Set<String> ids) async {
    for (final e in extrasBySession[sessionId] ?? []) {
      if (ids.contains(e.id)) e.synced = true;
    }
  }

  @override
  Future<List<StocktakeLocalMeta>> downloadedSessions() async =>
      metas.values.toList();

  @override
  Future<void> deleteSession(String sessionId) async {
    rowsBySession.remove(sessionId);
    extrasBySession.remove(sessionId);
    metas.remove(sessionId);
  }
}

void main() {
  late _MockRepo repo;
  late _MockOutbox outbox;
  late _FakeStore store;
  late StocktakeCountController c;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockRepo();
    outbox = _MockOutbox();
    store = _FakeStore();
    c = StocktakeCountController(
      repo: repo,
      store: store,
      outbox: outbox,
      attachments: _MockAttachments(),
      files: _MockFiles(),
      id: 's1',
    );
  });

  tearDown(Get.reset);

  Future<void> seed() async {
    await store.savePackage(
      sessionId: 's1',
      code: 'KK-1',
      name: 'Kiểm kê kho',
      type: 'supply',
      etag: 'W/"a"',
      items: [
        StocktakeLocalItem(
          itemId: 'i1',
          sessionId: 's1',
          code: 'VT001',
          name: 'Găng tay',
          lotId: 'l1',
          lotNo: 'L1',
          qrToken: 'QR-VT001',
          manufacturerCode: 'MC-001',
          bookQty: '10',
        ),
        StocktakeLocalItem(
          itemId: 'i2',
          sessionId: 's1',
          code: 'VT002',
          name: 'Kim tiêm',
          lotId: 'l2',
          lotNo: 'L2',
          bookQty: '5',
        ),
      ],
    );
  }

  test('load local + resolve theo code/lotNo', () async {
    await seed();
    when(() => repo.progress('s1')).thenAnswer(
      (_) async => const StocktakeProgress(total: 2, counted: 0, percent: 0),
    );
    await c.load();
    expect(c.items, hasLength(2));
    expect(c.resolve('vt001')?.itemId, 'i1');
    expect(c.resolve('QR-VT001')?.itemId, 'i1'); // qrToken (C14-C17)
    expect(c.resolve('MC-001')?.itemId, 'i1'); // mã hãng
    expect(c.resolve('L2')?.itemId, 'i2');
    expect(c.resolve('ZZ'), isNull);
  });

  test('saveCount ghi đè local + clientId mới + chưa gửi', () async {
    await seed();
    await c.load();
    final item = c.items.first;
    await c.saveCount(
      item,
      qty: '8',
      note: 'thiếu 2',
      photoFileId: 'file-photo-1',
    );
    final saved = c.items.firstWhere((e) => e.itemId == item.itemId);
    expect(saved.countedQty, '8');
    expect(saved.clientId, isNotNull);
    expect(saved.synced, isFalse);
    expect(saved.counted, isTrue);
    expect(saved.photoFileId, 'file-photo-1');
    expect(await store.pendingCount('s1'), 1);
  });

  test('saveCount giữ clientId đã dùng để xếp ảnh offline', () async {
    await seed();
    await c.load();
    await c.saveCount(c.items.first, qty: '9', clientId: 'count-client-1');
    expect(c.items.first.clientId, 'count-client-1');
  });

  test('addExtra lưu phát hiện thêm', () async {
    await seed();
    await c.load();
    await c.addExtra(code: 'LA-01', qty: '3', note: 'ngoài đợt');
    expect(c.extras, hasLength(1));
    expect(c.extras.single.code, 'LA-01');
    expect(await store.pendingCount('s1'), 1);
  });

  test('send enqueue batch counts + extras rồi chạy outbox', () async {
    await seed();
    when(
      () => repo.progress('s1'),
    ).thenAnswer((_) async => const StocktakeProgress());
    when(() => outbox.enqueue(any(), any())).thenAnswer((_) async => 'o1');
    when(() => outbox.run()).thenAnswer((_) async => true);
    await c.load();
    await c.saveCount(c.items.first, qty: '8', photoFileId: 'file-photo-1');
    await c.addExtra(code: 'LA-01', qty: '1');

    expect(await c.send(), isTrue);
    final payload =
        verify(
              () => outbox.enqueue('stocktake_counts', captureAny()),
            ).captured.single
            as Map<String, dynamic>;
    expect(payload['sessionId'], 's1');
    final counts = payload['counts'] as List<dynamic>;
    expect(counts, hasLength(2)); // 1 item + 1 extra
    final first = counts.first as Map<String, dynamic>;
    expect(first['itemId'], 'i1');
    expect(first['clientId'], isA<String>());
    expect(first['countedQty'], '8');
    expect(first['photoFileId'], 'file-photo-1');
    verify(() => outbox.run()).called(1);
  });

  test('send khi không có gì mới → không enqueue', () async {
    await seed();
    when(
      () => repo.progress('s1'),
    ).thenAnswer((_) async => const StocktakeProgress());
    await c.load();
    expect(await c.send(), isTrue);
    verifyNever(() => outbox.enqueue(any(), any()));
  });

  test(
    'handler map kết quả: accepted/duplicated → synced, conflicts → cờ',
    () async {
      await seed();
      await c.load();
      final a = c.items[0];
      final b = c.items[1];
      await c.saveCount(a, qty: '8');
      await c.saveCount(b, qty: '4');

      when(() => repo.postCounts('s1', any())).thenAnswer(
        (_) async => StocktakeCountResult(
          accepted: [a.clientId!],
          duplicated: [b.clientId!],
          conflicts: const [
            StocktakeConflict(
              clientId: 'other',
              itemId: 'i1',
              keptCountedAt: '2026-09-20T08:00:00Z',
            ),
          ],
        ),
      );
      final handler = StocktakeCountsOutboxHandler(repo: repo, store: store);
      expect(handler.type, 'stocktake_counts');
      await handler.send({
        'sessionId': 's1',
        'counts': [
          {'clientId': a.clientId, 'itemId': 'i1', 'countedQty': '8'},
          {'clientId': b.clientId, 'itemId': 'i2', 'countedQty': '4'},
        ],
      });
      expect(await store.pendingCount('s1'), 0);
      expect(store.rowsBySession['s1']![0].synced, isTrue);
      expect(store.rowsBySession['s1']![1].synced, isTrue);
    },
  );

  test('handler lỗi mạng → ném để outbox giữ lại', () async {
    when(() => repo.postCounts('s1', any())).thenThrow(Exception('offline'));
    final handler = StocktakeCountsOutboxHandler(repo: repo, store: store);
    await expectLater(
      () => handler.send({
        'sessionId': 's1',
        'counts': [
          {'clientId': 'c1', 'itemId': 'i1', 'countedQty': '1'},
        ],
      }),
      throwsA(isA<Exception>()),
    );
  });
}
