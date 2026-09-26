import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/data/models/kpi.dart';
import 'package:labasset_mobile/data/repositories/kpi_repository.dart';
import 'package:labasset_mobile/modules/kpi/kpi_controller.dart';

/// Kho giả: điều khiển điểm/hạng/board trả về để test controller.
class _FakeKpiRepo implements KpiRepository {
  String lastType = '';
  String? lastDetailId;
  int boardCalls = 0;
  num? rank = 8;
  num? total = 82.5;
  bool fail = false;

  KpiPerson _person(String type, {KpiTaskPage? tasks}) => KpiPerson(
    userId: 'u1',
    fullName: 'Nguyễn Văn An',
    type: type,
    start: '2026-09-01',
    end: '2026-09-30',
    total: total,
    rank: rank,
    credits: 12,
    items: 12,
    onTime: 91.7,
    areas: KpiAreas(
      repair: const KpiAreaScore(
        score: 88,
        volume: 100,
        onTime: 92,
        speed: 74,
        quality: 80,
        credits: 8,
        items: 8,
      ),
      maintenance: const KpiAreaScore(
        score: 70,
        volume: 62,
        onTime: 88,
        speed: 80,
        quality: 90,
        credits: 3,
        items: 3,
      ),
      calibration: const KpiAreaScore(
        score: 64,
        volume: 50,
        onTime: 100,
        quality: 75,
        credits: 1,
        items: 1,
      ),
    ),
    periods: const [
      KpiPoint(type: 'month', start: '2026-04-01', end: '2026-04-30'),
      KpiPoint(type: 'month', start: '2026-05-01', end: '2026-05-31'),
      KpiPoint(type: 'month', start: '2026-06-01', end: '2026-06-30'),
      KpiPoint(type: 'month', start: '2026-07-01', end: '2026-07-31'),
      KpiPoint(type: 'month', start: '2026-08-01', end: '2026-08-31'),
      KpiPoint(type: 'month', start: '2026-09-01', end: '2026-09-30'),
    ],
    tasks: tasks,
  );

  @override
  Future<KpiPerson> me({required String type, String? start}) async {
    lastType = type;
    if (fail) throw ApiError(500, 'INTERNAL_ERROR', '');
    return _person(type);
  }

  @override
  Future<KpiPerson> user(
    String id, {
    required String type,
    String? start,
    int page = 1,
    int limit = 20,
  }) async {
    lastDetailId = id;
    return _person(
      type,
      tasks: KpiTaskPage(
        items: const [
          KpiTaskItem(
            area: 'repair',
            id: 'r1',
            code: 'SC-001',
            title: 'Máy ly tâm',
            completedAt: '2026-09-20T10:00:00.000Z',
            onTime: true,
          ),
        ],
        total: 1,
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  Future<KpiBoard> board({required String type, String? start}) async {
    boardCalls++;
    return KpiBoard(
      type: type,
      start: '2026-09-01',
      end: '2026-09-30',
      totals: const KpiTotals(
        items: 40,
        credits: 30,
        onTime: 90,
        avgHandleHours: 6.5,
        avgQuality: 82,
      ),
      staff: const [
        KpiStaffRow(
          userId: 'u1',
          fullName: 'Nguyễn Văn An',
          total: 82.5,
          rank: 1,
          credits: 12,
          items: 12,
          onTime: 91.7,
        ),
        KpiStaffRow(
          userId: 'u2',
          fullName: 'Trần Thị B',
          total: 65,
          rank: 2,
          credits: 5,
          items: 5,
          onTime: 80,
        ),
        KpiStaffRow(
          userId: 'u3',
          fullName: 'Lê Văn C',
          total: 40,
          insufficient: true,
          credits: 1,
          items: 1,
          onTime: 100,
        ),
      ],
    );
  }

  @override
  Future<KpiPeriods> periods({required String type}) async =>
      KpiPeriods(type: type);
}

void main() {
  test('nạp điểm kỳ tháng hiện tại và đổi được sang tuần', () async {
    final repo = _FakeKpiRepo();
    final c = KpiController(repo: repo, userId: 'u1');
    await c.load();
    expect(c.score.value!.total, 82.5);
    expect(repo.lastType, 'month');
    await c.setPeriodType('week');
    expect(repo.lastType, 'week');
  });

  test('ẩn hạng khi API không trả rank', () async {
    final repo = _FakeKpiRepo()..rank = null;
    final c = KpiController(repo: repo, userId: 'u1');
    await c.load();
    expect(c.showRank, isFalse);
  });

  test('quản trị viện thấy tab Toàn viện', () async {
    final c = KpiController(repo: _FakeKpiRepo(), isAdmin: true);
    expect(c.tabs.length, 2);
    expect(c.tabs, [KpiTab.mine, KpiTab.hospital]);
  });

  test('kỹ thuật viên chỉ thấy tab của tôi', () async {
    final c = KpiController(repo: _FakeKpiRepo());
    expect(c.tabs.length, 1);
    expect(c.tabs.single, KpiTab.mine);
  });

  test('nạp danh sách việc hoàn tất của chính mình', () async {
    final repo = _FakeKpiRepo();
    final c = KpiController(repo: repo, userId: 'u1');
    await c.load();
    expect(repo.lastDetailId, 'u1');
    expect(c.tasks.single.code, 'SC-001');
    expect(c.history.length, 6);
  });

  test('kỳ không có việc: điểm null, không lỗi', () async {
    final repo = _FakeKpiRepo()..total = null;
    final c = KpiController(repo: repo, userId: 'u1');
    await c.load();
    expect(c.score.value!.total, isNull);
    expect(c.error.value, isNull);
  });

  test(
    'đổi tab Toàn viện nạp bảng xếp hạng, nhóm chưa đủ mẫu ở cuối',
    () async {
      final repo = _FakeKpiRepo();
      final c = KpiController(repo: repo, isAdmin: true);
      await c.load();
      await c.setTab(KpiTab.hospital);
      expect(repo.boardCalls, 1);
      expect(c.staff.map((s) => s.userId), ['u1', 'u2', 'u3']);
      expect(c.staff.last.insufficient, isTrue);
      expect(c.totals.value!.items, 40);
    },
  );

  test('lỗi API ghi error và giữ điểm rỗng', () async {
    final repo = _FakeKpiRepo()..fail = true;
    final c = KpiController(repo: repo, userId: 'u1');
    await c.load();
    expect(c.error.value, isA<ApiError>());
    expect(c.score.value, isNull);
    expect(c.loading.value, isFalse);
  });

  test(
    'chọn mảng mặc định là mảng nhiều đầu việc nhất, đủ bốn chỉ số',
    () async {
      final c = KpiController(repo: _FakeKpiRepo(), userId: 'u1');
      await c.load();
      expect(c.area.value, 'repair');
      expect(c.metricRows.map((r) => r.key), [
        'volume',
        'onTime',
        'speed',
        'quality',
      ]);
    },
  );

  test('mảng kiểm định chỉ còn ba chỉ số (không tốc độ)', () async {
    final c = KpiController(repo: _FakeKpiRepo(), userId: 'u1');
    await c.load();
    c.setArea('calibration');
    expect(c.metricRows.map((r) => r.key), ['volume', 'onTime', 'quality']);
  });
}
