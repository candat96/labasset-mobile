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
}
