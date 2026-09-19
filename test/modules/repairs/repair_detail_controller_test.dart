import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/sync/outbox_item.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/data/models/repair_detail.dart';
import 'package:labasset_mobile/data/repositories/repairs_repository.dart';
import 'package:labasset_mobile/modules/repairs/repair_detail_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepairs extends Mock implements RepairsRepository {}

class _MockOutbox extends Mock implements OutboxService {}

void main() {
  late _MockRepairs repo;
  late _MockOutbox outbox;

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
    repo = _MockRepairs();
    outbox = _MockOutbox();
    when(() => outbox.items()).thenAnswer((_) async => []);
  });

  tearDown(Get.reset);

  RepairDetailController controllerFor(
    RepairDetail detail, {
    List<String> roles = const ['EQUIPMENT_STAFF'],
    String userId = 'u1',
  }) {
    when(() => repo.detail(detail.id)).thenAnswer((_) async => detail);
    return RepairDetailController(
      repairs: repo,
      outbox: outbox,
      id: detail.id,
      userId: userId,
      roles: roles,
    );
  }

  RepairDetail detailWith({
    String status = 'new',
    String? assigneeId,
    List<RepairAssignment> assignments = const [],
  }) => RepairDetail(
    id: 'r1',
    code: 'SC-1',
    equipmentId: 'e1',
    status: status,
    assigneeId: assigneeId,
    assignments: assignments,
  );

  group('ma trận nút theo trạng thái/role', () {
    test('new + VT → Tiếp nhận, không Hoàn thành', () async {
      final c = controllerFor(detailWith());
      await c.load();
      expect(c.canAccept, isTrue);
      expect(c.canComplete, isFalse);
      expect(c.canAssign, isFalse); // VT không phải ADM
      expect(c.canCancel, isFalse);
    });

    test('new + ADM → Phân công + Huỷ', () async {
      final c = controllerFor(detailWith(), roles: ['HOSPITAL_ADMIN']);
      await c.load();
      expect(c.canAssign, isTrue);
      expect(c.canCancel, isTrue);
    });

    test(
      'in_progress + assignee → Chẩn đoán/Đổi trạng thái/Hoàn thành',
      () async {
        final c = controllerFor(
          detailWith(status: 'in_progress', assigneeId: 'u1'),
        );
        await c.load();
        expect(c.isAssignee, isTrue);
        expect(c.canDiagnose, isTrue);
        expect(c.canChangeStatus, isTrue);
        expect(c.canComplete, isTrue);
        expect(
          c.canCancel,
          isFalse,
        ); // đã qua completed? chưa, nhưng VT không phải ADM
      },
    );

    test('người khác xử lý → không thao tác', () async {
      final c = controllerFor(
        detailWith(status: 'in_progress', assigneeId: 'u9'),
      );
      await c.load();
      expect(c.isAssignee, isFalse);
      expect(c.canDiagnose, isFalse);
      expect(c.canComplete, isFalse);
    });

    test('assignment pending của tôi → Nhận việc/Từ chối', () async {
      final c = controllerFor(
        detailWith(
          status: 'accepted',
          assignments: const [
            RepairAssignment(id: 'a1', userId: 'u1', response: 'pending'),
          ],
        ),
      );
      await c.load();
      expect(c.canRespond, isTrue);
    });

    test('completed → Nghiệm thu; acceptance + ADM → Đóng', () async {
      final c = controllerFor(
        detailWith(status: 'completed'),
        roles: ['HOSPITAL_ADMIN'],
      );
      await c.load();
      expect(c.canAcceptance, isTrue);
      expect(c.canClose, isTrue);
      expect(c.canCancel, isFalse);
    });

    test('closed → không còn hành động ghi', () async {
      final c = controllerFor(
        detailWith(status: 'closed'),
        roles: ['HOSPITAL_ADMIN'],
      );
      await c.load();
      expect(c.canAssign, isFalse);
      expect(c.canCancel, isFalse);
      expect(c.canClose, isFalse);
    });
  });

  group('hành động gọi API + reload', () {
    test('accept gọi POST accept', () async {
      final c = controllerFor(detailWith());
      when(() => repo.accept('r1')).thenAnswer((_) async {});
      await c.load();
      expect(await c.accept(), isTrue);
      verify(() => repo.accept('r1')).called(1);
    });

    test('changeStatus gửi status + note', () async {
      final c = controllerFor(
        detailWith(status: 'in_progress', assigneeId: 'u1'),
      );
      when(
        () => repo.changeStatus('r1', 'awaiting_parts', 'chờ linh kiện'),
      ).thenAnswer((_) async {});
      await c.load();
      expect(await c.changeStatus('awaiting_parts', 'chờ linh kiện'), isTrue);
    });

    test('cancel gửi lý do', () async {
      final c = controllerFor(detailWith(), roles: ['HOSPITAL_ADMIN']);
      when(() => repo.cancel('r1', 'trùng phiếu')).thenAnswer((_) async {});
      await c.load();
      expect(await c.cancel('trùng phiếu'), isTrue);
    });
  });

  group('nhật ký offline', () {
    test('addLog enqueue outbox với clientId rồi chạy queue', () async {
      final c = controllerFor(
        detailWith(status: 'in_progress', assigneeId: 'u1'),
      );
      await c.load();
      when(() => outbox.enqueue(any(), any())).thenAnswer((_) async => 'o1');
      when(() => outbox.run()).thenAnswer((_) async => false); // offline
      await c.addLog(action: 'Thay bơm', note: 'xong');

      final captured =
          verify(
                () => outbox.enqueue('repair_log', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['ticketId'], 'r1');
      expect(captured['clientId'], isA<String>());
      expect(captured['action'], 'Thay bơm');
      verify(() => outbox.run()).called(1);
    });

    test('loadPendingLogs hiện log chờ đồng bộ đúng phiếu', () async {
      final c = controllerFor(detailWith());
      when(() => outbox.items()).thenAnswer(
        (_) async => [
          OutboxItem(
            id: 'o1',
            type: 'repair_log',
            payload: {
              'ticketId': 'r1',
              'clientId': 'c1',
              'at': '2026-09-19T08:00:00Z',
              'action': 'Kiểm tra',
            },
            createdAt: DateTime(2026, 9, 19, 8),
          ),
          OutboxItem(
            id: 'o2',
            type: 'repair_log',
            payload: {
              'ticketId': 'r2',
              'clientId': 'c2',
              'at': '2026-09-19T08:00:00Z',
              'action': 'Khác',
            },
            createdAt: DateTime(2026, 9, 19, 8),
          ),
        ],
      );
      await c.load();
      expect(c.pendingLogs, hasLength(1));
      expect(c.pendingLogs.single.pending, isTrue);
      expect(c.mergedLogs.single.action, 'Kiểm tra');
    });

    test('RepairLogOutboxHandler gửi payload đúng clientId', () async {
      when(
        () => repo.addLog(
          'r1',
          clientId: any(named: 'clientId'),
          at: any(named: 'at'),
          action: any(named: 'action'),
          note: any(named: 'note'),
          durationMinutes: any(named: 'durationMinutes'),
        ),
      ).thenAnswer((_) async {});
      final handler = RepairLogOutboxHandler(repo);
      expect(handler.type, 'repair_log');
      await handler.send({
        'ticketId': 'r1',
        'clientId': 'c1',
        'at': '2026-09-19T08:00:00Z',
        'action': 'Thay bơm',
        'note': 'ok',
        'durationMinutes': 30,
      });
      verify(
        () => repo.addLog(
          'r1',
          clientId: 'c1',
          at: '2026-09-19T08:00:00Z',
          action: 'Thay bơm',
          note: 'ok',
          durationMinutes: 30,
        ),
      ).called(1);
    });
  });
}
