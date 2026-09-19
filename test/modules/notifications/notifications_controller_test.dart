import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/modules/notifications/notifications_controller.dart';

void main() {
  test('mapPath maps equipment detail and known modules', () {
    expect(NotificationsController.mapPath('/equipment/abc'), '/equipment/abc');
    expect(
      NotificationsController.mapPath('/repairs/12'),
      '/placeholder/repairs',
    );
    expect(
      NotificationsController.mapPath('/calibrations'),
      '/placeholder/maintenance',
    );
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
        '/placeholder/repairs',
      );
      expect(
        NotificationsController.mapData({'taskId': 't1'}),
        '/placeholder/maintenance',
      );
      expect(
        NotificationsController.mapData({'requestId': 'q1'}),
        '/placeholder/requests',
      );
    });

    test('issueId/receiptId/alertId → kho, sessionId → kiểm kê', () {
      expect(
        NotificationsController.mapData({'issueId': 'i1'}),
        '/placeholder/stock',
      );
      expect(
        NotificationsController.mapData({'receiptId': 'p1'}),
        '/placeholder/stock',
      );
      expect(
        NotificationsController.mapData({'alertId': 'a1'}),
        '/placeholder/stock',
      );
      expect(
        NotificationsController.mapData({'sessionId': 's1'}),
        '/placeholder/stocktake',
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
