import 'package:json_annotation/json_annotation.dart';

part 'kpi.g.dart';

/// Điểm bốn chỉ số của một mảng (0..100, null = bỏ qua vì thiếu dữ liệu).
@JsonSerializable()
class KpiAreaScore {
  const KpiAreaScore({
    this.score,
    this.volume,
    this.onTime,
    this.speed,
    this.quality,
    this.credits = 0,
    this.items = 0,
    this.skipped = 0,
  });

  final num? score;
  final num? volume;
  final num? onTime;
  final num? speed;
  final num? quality;
  final num credits;
  final num items;
  final num skipped;

  factory KpiAreaScore.fromJson(Map<String, dynamic> json) =>
      _$KpiAreaScoreFromJson(json);
  Map<String, dynamic> toJson() => _$KpiAreaScoreToJson(this);
}

/// Ba điểm mảng; mảng không có đầu việc nào là null.
@JsonSerializable(explicitToJson: true)
class KpiAreas {
  const KpiAreas({this.repair, this.maintenance, this.calibration});

  final KpiAreaScore? repair;
  final KpiAreaScore? maintenance;
  final KpiAreaScore? calibration;

  KpiAreaScore? area(String name) => switch (name) {
    'repair' => repair,
    'maintenance' => maintenance,
    'calibration' => calibration,
    _ => null,
  };

  factory KpiAreas.fromJson(Map<String, dynamic> json) =>
      _$KpiAreasFromJson(json);
  Map<String, dynamic> toJson() => _$KpiAreasToJson(this);
}

@JsonSerializable()
class KpiAreaWeights {
  const KpiAreaWeights({
    this.repair = 0,
    this.maintenance = 0,
    this.calibration = 0,
  });

  final num repair;
  final num maintenance;
  final num calibration;

  factory KpiAreaWeights.fromJson(Map<String, dynamic> json) =>
      _$KpiAreaWeightsFromJson(json);
  Map<String, dynamic> toJson() => _$KpiAreaWeightsToJson(this);
}

/// Trọng số áp dụng cho kỳ (lấy lúc chốt nếu kỳ đã chốt).
@JsonSerializable(explicitToJson: true)
class KpiWeights {
  const KpiWeights({
    this.areaWeights = const KpiAreaWeights(),
    this.metricWeights = const {},
    this.minItems = 3,
    this.assistantWeight = 0.5,
    this.countBy = 'completed',
  });

  final KpiAreaWeights areaWeights;
  final Map<String, dynamic> metricWeights;
  final num minItems;
  final num assistantWeight;
  final String countBy;

  factory KpiWeights.fromJson(Map<String, dynamic> json) =>
      _$KpiWeightsFromJson(json);
  Map<String, dynamic> toJson() => _$KpiWeightsToJson(this);
}

/// Một điểm trong biểu đồ 6 kỳ gần nhất.
@JsonSerializable()
class KpiPoint {
  const KpiPoint({
    required this.type,
    required this.start,
    required this.end,
    this.total,
    this.rank,
  });

  final String type;
  final String start;
  final String end;
  final num? total;
  final num? rank;

  factory KpiPoint.fromJson(Map<String, dynamic> json) =>
      _$KpiPointFromJson(json);
  Map<String, dynamic> toJson() => _$KpiPointToJson(this);
}

/// Một đầu việc đã hoàn tất trong kỳ.
@JsonSerializable()
class KpiTaskItem {
  const KpiTaskItem({
    required this.area,
    required this.id,
    required this.code,
    required this.title,
    this.equipmentName,
    this.departmentName,
    this.completedAt,
    this.onTime = true,
    this.quality,
  });

  final String area; // repair | maintenance | calibration
  final String id;
  final String code;
  final String title;
  final String? equipmentName;
  final String? departmentName;
  final String? completedAt;
  final bool onTime;
  final num? quality;

  factory KpiTaskItem.fromJson(Map<String, dynamic> json) =>
      _$KpiTaskItemFromJson(json);
  Map<String, dynamic> toJson() => _$KpiTaskItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class KpiTaskPage {
  const KpiTaskPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<KpiTaskItem> items;
  final num total;
  final num page;
  final num limit;

  factory KpiTaskPage.fromJson(Map<String, dynamic> json) =>
      _$KpiTaskPageFromJson(json);
  Map<String, dynamic> toJson() => _$KpiTaskPageToJson(this);
}

/// `GET /v1/performance/me` (và `users/:id`) — điểm của một người trong kỳ.
@JsonSerializable(explicitToJson: true)
class KpiPerson {
  const KpiPerson({
    required this.userId,
    required this.fullName,
    this.inactive = false,
    required this.type,
    required this.start,
    required this.end,
    this.total,
    this.rank,
    this.insufficient = false,
    this.credits = 0,
    this.items = 0,
    this.onTime,
    this.skipped = 0,
    this.areas = const KpiAreas(),
    this.weights = const KpiWeights(),
    this.periods = const [],
    this.tasks,
  });

  final String userId;
  final String fullName;
  final bool inactive;
  final String type;
  final String start;
  final String end;
  final num? total;
  final num? rank;
  final bool insufficient;
  final num credits;
  final num items;
  final num? onTime;
  final num skipped;
  final KpiAreas areas;
  final KpiWeights weights;
  final List<KpiPoint> periods;

  /// Chỉ có ở `/v1/performance/users/:id`.
  final KpiTaskPage? tasks;

  factory KpiPerson.fromJson(Map<String, dynamic> json) =>
      _$KpiPersonFromJson(json);
  Map<String, dynamic> toJson() => _$KpiPersonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class KpiTotals {
  const KpiTotals({
    this.items = 0,
    this.credits = 0,
    this.onTime,
    this.avgHandleHours,
    this.avgQuality,
  });

  final num items;
  final num credits;
  final num? onTime;
  final num? avgHandleHours;
  final num? avgQuality;

  factory KpiTotals.fromJson(Map<String, dynamic> json) =>
      _$KpiTotalsFromJson(json);
  Map<String, dynamic> toJson() => _$KpiTotalsToJson(this);
}

/// Một dòng bảng xếp hạng toàn viện.
@JsonSerializable(explicitToJson: true)
class KpiStaffRow {
  const KpiStaffRow({
    required this.userId,
    required this.fullName,
    this.departmentId,
    this.inactive = false,
    this.total,
    this.rank,
    this.rankChange,
    this.insufficient = false,
    this.credits = 0,
    this.items = 0,
    this.onTime,
    this.avgHandleHours,
    this.avgQuality,
    this.skipped = 0,
    this.areas = const KpiAreas(),
  });

  final String userId;
  final String fullName;
  final String? departmentId;
  final bool inactive;
  final num? total;
  final num? rank;
  final num? rankChange;
  final bool insufficient;
  final num credits;
  final num items;
  final num? onTime;
  final num? avgHandleHours;
  final num? avgQuality;
  final num skipped;
  final KpiAreas areas;

  factory KpiStaffRow.fromJson(Map<String, dynamic> json) =>
      _$KpiStaffRowFromJson(json);
  Map<String, dynamic> toJson() => _$KpiStaffRowToJson(this);
}

/// `GET /v1/performance` — bảng xếp hạng toàn viện một kỳ.
@JsonSerializable(explicitToJson: true)
class KpiBoard {
  const KpiBoard({
    required this.type,
    required this.start,
    required this.end,
    this.locked = false,
    this.lockedBy,
    this.lockedAt,
    this.note,
    this.weights = const KpiWeights(),
    this.totals = const KpiTotals(),
    this.staff = const [],
  });

  final String type;
  final String start;
  final String end;
  final bool locked;
  final String? lockedBy;
  final String? lockedAt;
  final String? note;
  final KpiWeights weights;
  final KpiTotals totals;
  final List<KpiStaffRow> staff;

  factory KpiBoard.fromJson(Map<String, dynamic> json) =>
      _$KpiBoardFromJson(json);
  Map<String, dynamic> toJson() => _$KpiBoardToJson(this);
}

@JsonSerializable()
class KpiPeriodItem {
  const KpiPeriodItem({
    required this.type,
    required this.start,
    required this.end,
    this.locked = false,
    this.lockedBy,
    this.lockedAt,
    this.note,
  });

  final String type;
  final String start;
  final String end;
  final bool locked;
  final String? lockedBy;
  final String? lockedAt;
  final String? note;

  factory KpiPeriodItem.fromJson(Map<String, dynamic> json) =>
      _$KpiPeriodItemFromJson(json);
  Map<String, dynamic> toJson() => _$KpiPeriodItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class KpiPeriods {
  const KpiPeriods({required this.type, this.periods = const []});

  final String type;
  final List<KpiPeriodItem> periods;

  factory KpiPeriods.fromJson(Map<String, dynamic> json) =>
      _$KpiPeriodsFromJson(json);
  Map<String, dynamic> toJson() => _$KpiPeriodsToJson(this);
}
