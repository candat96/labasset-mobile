import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../core/errors/api_error.dart';
import 'outbox_item.dart';
import 'outbox_store.dart';

/// Handler gửi một loại thao tác offline lên API (idempotent bằng `clientId`).
abstract class OutboxHandler {
  String get type;
  Future<void> send(Map<String, dynamic> payload);
}

/// Hàng đợi thao tác offline: sqflite + connectivity, thử lại backoff.
class OutboxService extends GetxService {
  OutboxService({
    required OutboxStore store,
    Future<bool> Function()? online,
    this.baseBackoff = const Duration(seconds: 30),
    this.maxBackoff = const Duration(hours: 1),
    DateTime Function()? now,
  }) : _store = store,
       _online = online,
       _now = now ?? DateTime.now;

  final OutboxStore _store;
  final Future<bool> Function()? _online;
  final DateTime Function() _now;
  final Duration baseBackoff;
  final Duration maxBackoff;

  final Map<String, OutboxHandler> _handlers = {};
  final RxInt pending = 0.obs;
  final RxInt failed = 0.obs;
  final RxBool running = false.obs;

  bool _started = false;
  StreamSubscription<bool>? _sub;

  Future<void> init() async {
    await _store.init();
    await refreshCounts();
  }

  /// Bắt đầu nghe mạng: có mạng → chạy hàng đợi.
  Future<void> start({Stream<bool>? connectivity}) async {
    if (_started) return;
    _started = true;
    if (connectivity != null) {
      _sub = connectivity.listen((hasNetwork) {
        if (hasNetwork) unawaited(run());
      });
    }
    await run();
  }

  void addHandler(OutboxHandler handler) => _handlers[handler.type] = handler;

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }

  Future<void> refreshCounts() async {
    final items = await _store.all();
    pending.value = items.length;
    failed.value = items.where((i) => i.attempts > 0).length;
  }

  Future<List<OutboxItem>> items() => _store.all();

  Future<String> enqueue(String type, Map<String, dynamic> payload) async {
    final id = '${_now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    await _store.insert(
      OutboxItem(id: id, type: type, payload: payload, createdAt: _now()),
    );
    await refreshCounts();
    return id;
  }

  Duration backoffFor(int attempts) {
    final seconds = baseBackoff.inSeconds * pow(2, min(attempts, 10));
    final capped = seconds.clamp(0, maxBackoff.inSeconds.toDouble());
    return Duration(seconds: capped.round());
  }

  Future<bool> _isOnline() async {
    final online = _online;
    if (online == null) return true;
    try {
      return await online();
    } catch (_) {
      return false;
    }
  }

  /// Gửi các thao tác đến hạn. Trả false nếu đang offline (không chạy).
  Future<bool> run({bool manual = false}) async {
    if (running.value) return true;
    if (!await _isOnline()) {
      await refreshCounts();
      return false;
    }
    running.value = true;
    try {
      final items = await _store.all();
      for (final item in items) {
        if (!manual && _inBackoff(item)) continue;
        final handler = _handlers[item.type];
        if (handler == null) continue; // chờ module đăng ký handler
        try {
          await handler.send(item.payload);
          await _store.delete(item.id);
        } catch (e) {
          final err = ApiError.from(e);
          if (err.code == 'NETWORK_ERROR' || err.status == 0) {
            break; // mất mạng giữa chừng → dừng, thử lượt sau
          }
          await _store.update(
            item.copyWith(
              attempts: item.attempts + 1,
              lastError: err.code,
              lastAttemptAt: _now(),
            ),
          );
        }
      }
      await refreshCounts();
      return true;
    } finally {
      running.value = false;
    }
  }

  bool _inBackoff(OutboxItem item) {
    final at = item.lastAttemptAt;
    if (at == null) return false;
    return _now().isBefore(at.add(backoffFor(item.attempts)));
  }

  /// Thử lại toàn bộ: xoá backoff/lỗi rồi chạy ngay.
  Future<bool> retryAll() async {
    final items = await _store.all();
    for (final item in items) {
      await _store.update(
        OutboxItem(
          id: item.id,
          type: item.type,
          payload: item.payload,
          createdAt: item.createdAt,
        ),
      );
    }
    await refreshCounts();
    return run(manual: true);
  }

  @override
  void onClose() {
    unawaited(stop());
    super.onClose();
  }
}
