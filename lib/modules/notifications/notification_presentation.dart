import '../../data/models/notification_item.dart';

enum NotificationSection { today, yesterday, thisWeek, older }

NotificationSection notificationSection(String createdAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final parsed = DateTime.tryParse(createdAt)?.toLocal();
  if (parsed == null) return NotificationSection.older;
  final today = DateTime(current.year, current.month, current.day);
  final date = DateTime(parsed.year, parsed.month, parsed.day);
  final days = today.difference(date).inDays;
  if (days <= 0) return NotificationSection.today;
  if (days == 1) return NotificationSection.yesterday;
  if (days < 7) return NotificationSection.thisWeek;
  return NotificationSection.older;
}

String notificationSectionLabel(NotificationSection section) =>
    switch (section) {
      NotificationSection.today => 'HÔM NAY',
      NotificationSection.yesterday => 'HÔM QUA',
      NotificationSection.thisWeek => 'TUẦN NÀY',
      NotificationSection.older => 'CŨ HƠN',
    };

String notificationBody(String body) =>
    body.replaceFirst(RegExp(r'^\s*\[[^\]]+\]\s*'), '').trim();

String notificationTitle(NotificationItem item) {
  final raw = item.title.trim();
  if (!_looksLikeCode(raw)) return raw;
  if (item.type.startsWith('repair.')) {
    return 'Phiếu sửa chữa $raw có cập nhật';
  }
  if (item.type.startsWith('request.')) {
    return 'Phiếu yêu cầu $raw có cập nhật';
  }
  if (item.type.startsWith('equipment.transfer.')) {
    return 'Điều chuyển $raw có cập nhật';
  }
  return 'Thông báo $raw';
}

bool _looksLikeCode(String value) => RegExp(
  r'^[A-ZĐ]{1,8}[-_/]?\d[\w\-/.]*$',
  caseSensitive: false,
).hasMatch(value);
