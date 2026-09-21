import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/data/models/notification_item.dart';
import 'package:labasset_mobile/modules/notifications/notification_presentation.dart';

void main() {
  test('nhóm thông báo theo ngày', () {
    final now = DateTime(2026, 9, 21, 12);
    expect(
      notificationSection('2026-09-21T01:00:00', now: now),
      NotificationSection.today,
    );
    expect(
      notificationSection('2026-09-20T01:00:00', now: now),
      NotificationSection.yesterday,
    );
    expect(
      notificationSection('2026-09-17T01:00:00', now: now),
      NotificationSection.thisWeek,
    );
    expect(
      notificationSection('2026-09-01T01:00:00', now: now),
      NotificationSection.older,
    );
  });

  test('làm tự nhiên tiêu đề mã sửa chữa và bỏ tiền tố mô tả', () {
    const item = NotificationItem(
      id: 'n1',
      createdAt: '2026-09-21T01:00:00Z',
      type: 'repair.new',
      title: 'SC-000123',
      body: '[repair] Máy đang chờ tiếp nhận',
    );
    expect(notificationTitle(item), 'Phiếu sửa chữa SC-000123 có cập nhật');
    expect(notificationBody(item.body), 'Máy đang chờ tiếp nhận');
  });
}
