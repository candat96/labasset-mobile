import 'package:json_annotation/json_annotation.dart';

part 'stocktake.g.dart';

/// `GET /v1/stocktakes` → session rút gọn + assignments + counts.
@JsonSerializable()
class StocktakeSession {
  const StocktakeSession({
    required this.id,
    required this.code,
    this.type = 'equipment',
    this.scopeType = 'all',
    this.scopeId,
    this.name = '',
    this.plannedAt,
    this.status = 'open',
    this.assignments = const [],
    this.total = 0,
    this.counted = 0,
    this.diff = 0,
  });

  final String id;
  final String code;
  final String type;
  final String scopeType;
  final String? scopeId;
  final String name;
  final String? plannedAt;
  final String status;
  final List<StocktakeAssignment> assignments;
  final num total;
  final num counted;
  final num diff;

  double get percent => total == 0 ? 0 : counted / total;

  bool assignedTo(String userId) => assignments.any((a) => a.userId == userId);

  factory StocktakeSession.fromJson(Map<String, dynamic> json) =>
      _$StocktakeSessionFromJson(json);
  Map<String, dynamic> toJson() => _$StocktakeSessionToJson(this);
}

@JsonSerializable()
class StocktakeAssignment {
  const StocktakeAssignment({
    required this.userId,
    this.fullName,
    this.subScope,
    this.progress = 0,
  });

  final String userId;
  final String? fullName;
  final Map<String, dynamic>? subScope;
  final num progress;

  factory StocktakeAssignment.fromJson(Map<String, dynamic> json) =>
      _$StocktakeAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$StocktakeAssignmentToJson(this);
}

@JsonSerializable()
class StocktakePage {
  const StocktakePage({required this.items, this.total = 0});

  final List<StocktakeSession> items;
  final num total;

  factory StocktakePage.fromJson(Map<String, dynamic> json) =>
      _$StocktakePageFromJson(json);
  Map<String, dynamic> toJson() => _$StocktakePageToJson(this);
}

/// Một dòng trong `GET /:id/package` (rút gọn).
@JsonSerializable()
class StocktakePackageItem {
  const StocktakePackageItem({
    required this.itemId,
    this.equipmentId,
    this.lotId,
    this.supplyId,
    required this.code,
    required this.name,
    this.location,
    this.lotNo,
    this.bookQty = '1',
    this.qrToken,
  });

  final String itemId;
  final String? equipmentId;
  final String? lotId;
  final String? supplyId;
  final String code;
  final String name;
  final String? location;
  final String? lotNo;
  final String bookQty;

  /// API package chưa trả qrToken (TODO(api)) — tạm tra bằng `code`.
  final String? qrToken;

  bool get isEquipment => equipmentId != null;

  factory StocktakePackageItem.fromJson(Map<String, dynamic> json) =>
      _$StocktakePackageItemFromJson(json);
  Map<String, dynamic> toJson() => _$StocktakePackageItemToJson(this);
}

@JsonSerializable()
class StocktakeProgress {
  const StocktakeProgress({this.total = 0, this.counted = 0, this.percent = 0});

  final num total;
  final num counted;
  final num percent;

  factory StocktakeProgress.fromJson(Map<String, dynamic> json) =>
      _$StocktakeProgressFromJson(json);
  Map<String, dynamic> toJson() => _$StocktakeProgressToJson(this);
}

/// Kết quả `POST /:id/counts`.
class StocktakeCountResult {
  const StocktakeCountResult({
    this.accepted = const [],
    this.duplicated = const [],
    this.conflicts = const [],
    this.extras = const [],
  });

  final List<String> accepted;
  final List<String> duplicated;
  final List<StocktakeConflict> conflicts;
  final List<String> extras;

  static StocktakeCountResult fromJson(Map<String, dynamic> json) {
    List<String> ids(Object? raw) => (raw as List<dynamic>? ?? [])
        .map((e) => e is Map ? (e['clientId'] as String?) ?? '' : '$e')
        .where((s) => s.isNotEmpty)
        .toList();
    final rawConflicts = json['conflicts'] as List<dynamic>? ?? [];
    return StocktakeCountResult(
      accepted: ids(json['accepted']),
      duplicated: ids(json['duplicated']),
      conflicts: rawConflicts
          .whereType<Map<String, dynamic>>()
          .map(StocktakeConflict.fromJson)
          .toList(),
      extras: ids(json['extras']),
    );
  }
}

@JsonSerializable()
class StocktakeConflict {
  const StocktakeConflict({
    required this.clientId,
    this.itemId,
    this.keptCountedAt,
  });

  final String clientId;
  final String? itemId;
  final String? keptCountedAt;

  factory StocktakeConflict.fromJson(Map<String, dynamic> json) =>
      _$StocktakeConflictFromJson(json);
  Map<String, dynamic> toJson() => _$StocktakeConflictToJson(this);
}
