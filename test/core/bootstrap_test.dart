import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/bootstrap.dart';
import 'package:labasset_mobile/core/cache/kv_cache.dart';
import 'package:labasset_mobile/core/stocktake/stocktake_local_store.dart';
import 'package:labasset_mobile/core/sync/outbox_store.dart';
import 'package:mocktail/mocktail.dart';

class _Cache extends Mock implements KvCache {}

class _StocktakeStore extends Mock implements StocktakeLocalStore {}

class _OutboxStore extends Mock implements OutboxStore {}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('đăng ký các kho cục bộ theo interface mà route sử dụng', () {
    final cache = _Cache();
    final stocktakeStore = _StocktakeStore();
    final outboxStore = _OutboxStore();

    registerLocalStores(
      stocktakeStore: stocktakeStore,
      cache: cache,
      outboxStore: outboxStore,
    );

    expect(Get.find<KvCache>(), same(cache));
    expect(Get.find<StocktakeLocalStore>(), same(stocktakeStore));
    expect(Get.find<OutboxStore>(), same(outboxStore));
  });
}
