import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/sync/outbox_item.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/core/sync/outbox_store.dart';

class _FakeStore implements OutboxStore {
  final List<OutboxItem> rows = [];
  int _seq = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> insert(OutboxItem item) async => rows.add(item);

  @override
  Future<void> update(OutboxItem item) async {
    final i = rows.indexWhere((r) => r.id == item.id);
    if (i >= 0) rows[i] = item;
  }

  @override
  Future<void> delete(String id) async => rows.removeWhere((r) => r.id == id);

  @override
  Future<List<OutboxItem>> all() async => List.of(rows);

  @override
  Future<void> clear() async => rows.clear();

  String nextId() => 'id${_seq++}';
}

class _Handler implements OutboxHandler {
  _Handler(this.type, this.onSend);
  @override
  final String type;
  final Future<void> Function(Map<String, dynamic>) onSend;
  final List<Map<String, dynamic>> sent = [];
  @override
  Future<void> send(Map<String, dynamic> payload) async {
    await onSend(payload);
    sent.add(payload);
  }
}

void main() {
  late _FakeStore store;
  late OutboxService service;

  setUp(() {
    store = _FakeStore();
    service = OutboxService(store: store, online: () async => true);
  });

  test('enqueue → gửi thành công → xoá khỏi hàng đợi', () async {
    final handler = _Handler('repair_log', (_) async {});
    service.addHandler(handler);
    await service.enqueue('repair_log', {'clientId': 'c1'});
    expect(service.pending.value, 1);

    expect(await service.run(), isTrue);
    expect(handler.sent.single['clientId'], 'c1');
    expect(store.rows, isEmpty);
    expect(service.pending.value, 0);
  });

  test('lỗi API → giữ lại, tăng attempts, ghi lastError', () async {
    service.addHandler(
      _Handler(
        'repair_log',
        (_) async => throw ApiError(500, 'INTERNAL_ERROR', ''),
      ),
    );
    await service.enqueue('repair_log', {'clientId': 'c2'});
    await service.run();
    expect(store.rows.single.attempts, 1);
    expect(store.rows.single.lastError, 'INTERNAL_ERROR');
    expect(service.failed.value, 1);
  });

  test('mất mạng → không chạy, giữ nguyên hàng đợi', () async {
    service = OutboxService(store: store, online: () async => false);
    await service.enqueue('repair_log', {});
    expect(await service.run(), isFalse);
    expect(store.rows, hasLength(1));
  });

  test('backoff: lần lỗi gần nhất chặn gửi lại cho tới hạn', () async {
    var calls = 0;
    service.addHandler(
      _Handler('x', (_) async {
        calls++;
        throw ApiError(500, 'INTERNAL_ERROR', '');
      }),
    );
    await service.enqueue('x', {});
    await service.run();
    await service.run();
    expect(calls, 1, reason: 'trong thời gian backoff không gọi lại');

    // Quá hạn backoff (baseBackoff 0) → gọi lại.
    service =
        OutboxService(
          store: store,
          online: () async => true,
          baseBackoff: Duration.zero,
        )..addHandler(
          _Handler('x', (_) async {
            calls++;
            throw ApiError(500, 'INTERNAL_ERROR', '');
          }),
        );
    await service.run();
    expect(calls, 2);
  });

  test('retryAll xoá lỗi và chạy manual', () async {
    var fail = true;
    service.addHandler(
      _Handler('x', (_) async {
        if (fail) throw ApiError(500, 'INTERNAL_ERROR', '');
      }),
    );
    await service.enqueue('x', {});
    await service.run();
    expect(service.failed.value, 1);

    fail = false;
    await service.retryAll();
    expect(store.rows, isEmpty);
    expect(service.pending.value, 0);
  });

  test('handler chưa đăng ký → giữ lại chờ module', () async {
    await service.enqueue('stocktake_count', {});
    await service.run();
    expect(store.rows, hasLength(1));
    expect(store.rows.single.attempts, 0);
  });
}
