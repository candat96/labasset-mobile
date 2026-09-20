import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/modules/notifications/notifications_controller.dart';

void main() {
  test('mapPath maps equipment detail and known modules', () {
    expect(NotificationsController.mapPath('/equipment/abc'), '/equipment/abc');
    expect(NotificationsController.mapPath('/repairs/12'), '/repairs/12');
    expect(NotificationsController.mapPath('/calibrations'), '/calibrations');
    expect(NotificationsController.mapPath('/admin/users'), isNull);
    expect(NotificationsController.mapPath(''), isNull);
  });

  group('mapData theo 00 §2.10', () {
    test('equipmentId ưu tiên mở hồ sơ máy', () {
      expect(
        NotificationsController.mapData({
          'equipmentId': 'e1',
          'repairTicketId': 'r1',
        }),
        '/equipment/e1',
      );
    });

    test('repairTicketId/taskId/requestId → module tương ứng', () {
      expect(
        NotificationsController.mapData({'repairTicketId': 'r1'}),
        '/repairs/r1',
      );
      expect(
        NotificationsController.mapData({'taskId': 't1'}),
        '/maintenance/tasks/t1',
      );
      expect(
        NotificationsController.mapData({'requestId': 'q1'}),
        '/requests/q1',
      );
    });

    test('issueId/receiptId/alertId → kho, sessionId → kiểm kê', () {
      expect(
        NotificationsController.mapData({'issueId': 'i1'}),
        '/stock/issues/i1',
      );
      expect(
        NotificationsController.mapData({'receiptId': 'p1'}),
        '/stock/receipts/p1',
      );
      expect(
        NotificationsController.mapData({'alertId': 'a1'}),
        '/stock/alerts?alertId=a1',
      );
      expect(
        NotificationsController.mapData({'sessionId': 's1'}),
        '/stocktakes/s1',
      );
    });

    test('supplyId/lotId mở màn vật tư', () {
      expect(
        NotificationsController.mapData({'supplyId': 'supply-1'}),
        '/supplies/supply-1',
      );
      expect(
        NotificationsController.mapData({'lotId': 'lot-1'}),
        '/stock/lookup?lotId=lot-1',
      );
    });

    test('data rỗng/lạ → null', () {
      expect(NotificationsController.mapData(null), isNull);
      expect(NotificationsController.mapData(const {}), isNull);
      expect(NotificationsController.mapData(const {'foo': 'bar'}), isNull);
      expect(
        NotificationsController.mapData(const {'repairTicketId': ''}),
        isNull,
      );
    });
  });
}
