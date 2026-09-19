import 'dart:convert';

/// Một thao tác chờ gửi trong bảng `outbox`.
class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
    this.lastAttemptAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  final DateTime? lastAttemptAt;

  OutboxItem copyWith({
    int? attempts,
    String? lastError,
    DateTime? lastAttemptAt,
  }) => OutboxItem(
    id: id,
    type: type,
    payload: payload,
    createdAt: createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError ?? this.lastError,
    lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'type': type,
    'payload': jsonEncode(payload),
    'createdAt': createdAt.millisecondsSinceEpoch,
    'attempts': attempts,
    'lastError': lastError,
    'lastAttemptAt': lastAttemptAt?.millisecondsSinceEpoch,
  };

  static OutboxItem fromRow(Map<String, Object?> row) => OutboxItem(
    id: row['id'] as String,
    type: row['type'] as String,
    payload:
        jsonDecode(row['payload'] as String? ?? '{}') as Map<String, dynamic>,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (row['createdAt'] as num?)?.toInt() ?? 0,
    ),
    attempts: (row['attempts'] as num?)?.toInt() ?? 0,
    lastError: row['lastError'] as String?,
    lastAttemptAt: row['lastAttemptAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            (row['lastAttemptAt'] as num).toInt(),
          ),
  );
}
