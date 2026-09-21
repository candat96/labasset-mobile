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

  test('mapPath giữ đúng id kiểm kê và vật tư', () {
    expect(
      NotificationsController.mapPath('/stocktakes/st-1'),
      '/stocktakes/st-1',
    );
    expect(
      NotificationsController.mapPath('/supplies/supply-1'),
      '/supplies/supply-1',
    );
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

    test('demand.request_* ưu tiên mở phiếu dự trù (không nhầm C2)', () {
      expect(
        NotificationsController.mapData({
          'requestId': 'dr1',
          'periodId': 'p1',
        }, type: 'demand.request_submitted'),
        '/demand/requests/dr1',
      );
      expect(
        NotificationsController.mapData({
          'requestId': 'dr1',
        }, type: 'demand.request_returned'),
        '/demand/requests/dr1',
      );
    });

    test('demand.period_* / deadline_soon → màn kỳ dự trù', () {
      expect(
        NotificationsController.mapData({
          'periodId': 'p1',
        }, type: 'demand.period_opened'),
        '/demand/periods/p1',
      );
      expect(
        NotificationsController.mapData({
          'periodId': 'p1',
        }, type: 'demand.period_closed'),
        '/demand/periods/p1',
      );
      expect(
        NotificationsController.mapData(const {}, type: 'demand.deadline_soon'),
        '/demand',
      );
    });
  });
}
