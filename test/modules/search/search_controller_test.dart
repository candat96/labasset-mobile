import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/data/models/global_search.dart';
import 'package:labasset_mobile/data/repositories/search_repository.dart';
import 'package:labasset_mobile/modules/search/search_controller.dart';
import 'package:mocktail/mocktail.dart';

class _Search extends Mock implements SearchRepository {}

void main() {
  late _Search repository;
  late GlobalSearchController controller;
  late List<String> routes;

  setUp(() {
    Get.testMode = true;
    repository = _Search();
    routes = [];
    controller = GlobalSearchController(
      repository: repository,
      navigate: (route) async => routes.add(route),
    );
  });
  tearDown(Get.reset);

  test('dưới 2 ký tự không gọi API', () async {
    await controller.search('a');
    verifyZeroInteractions(repository);
    expect(controller.searched.value, isFalse);
  });

  test('một call tạo đủ nhóm kết quả và bỏ nhóm rỗng', () async {
    when(() => repository.search('máy', limit: 5)).thenAnswer(
      (_) async => const GlobalSearchResponse(
        equipment: [
          GlobalSearchHit(
            id: 'e1',
            code: 'M1',
            title: 'Máy thở',
            subtitle: 'Khoa ICU',
            link: '/equipment/e1',
          ),
        ],
        supplies: [],
        repairs: [],
        requests: [],
        faults: [
          GlobalSearchHit(
            id: 'f1',
            code: 'E12',
            title: 'Lỗi áp suất',
            subtitle: '',
            link: '/faults/f1',
          ),
        ],
      ),
    );

    await controller.search('máy');

    expect(controller.groups.map((group) => group.key), [
      'equipment',
      'faults',
    ]);
    expect(controller.groups.first.hits.first.title, 'M1 — Máy thở');
    verify(() => repository.search('máy', limit: 5)).called(1);
  });

  test('API lỗi giữ error cho ErrorState', () async {
    when(
      () => repository.search('máy', limit: 5),
    ).thenThrow(ApiError(0, 'NETWORK_ERROR', ''));
    await controller.search('máy');
    expect(controller.groups, isEmpty);
    expect(controller.error.value, isNotNull);
    expect(controller.searched.value, isTrue);
  });

  test('mở kết quả điều hướng route mobile', () async {
    await controller.open(
      const SearchHit(
        id: 'e1',
        title: 'Máy',
        subtitle: '',
        route: '/equipment/e1',
      ),
    );
    expect(routes, ['/equipment/e1']);
  });

  test('kết quả rỗng vẫn đánh dấu đã tìm', () async {
    when(() => repository.search('xyz', limit: 5)).thenAnswer(
      (_) async => const GlobalSearchResponse(
        equipment: [],
        supplies: [],
        repairs: [],
        requests: [],
        faults: [],
      ),
    );
    await controller.search('xyz');
    expect(controller.searched.value, isTrue);
    expect(controller.groups, isEmpty);
    expect(controller.error.value, isNull);
  });

  test('thư viện lỗi dùng route placeholder an toàn trên mobile', () async {
    when(() => repository.search('E12', limit: 5)).thenAnswer(
      (_) async => const GlobalSearchResponse(
        equipment: [],
        supplies: [],
        repairs: [],
        requests: [],
        faults: [
          GlobalSearchHit(
            id: 'f1',
            code: 'E12',
            title: 'Lỗi áp suất',
            subtitle: '',
            link: '/faults/f1',
          ),
        ],
      ),
    );
    await controller.search('E12');
    expect(controller.groups.single.hits.single.route, '/placeholder/faults');
  });
}
