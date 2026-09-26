// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kpi.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KpiAreaScore _$KpiAreaScoreFromJson(Map<String, dynamic> json) => KpiAreaScore(
  score: json['score'] as num?,
  volume: json['volume'] as num?,
  onTime: json['onTime'] as num?,
  speed: json['speed'] as num?,
  quality: json['quality'] as num?,
  credits: json['credits'] as num? ?? 0,
  items: json['items'] as num? ?? 0,
  skipped: json['skipped'] as num? ?? 0,
);

Map<String, dynamic> _$KpiAreaScoreToJson(KpiAreaScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'volume': instance.volume,
      'onTime': instance.onTime,
      'speed': instance.speed,
      'quality': instance.quality,
      'credits': instance.credits,
      'items': instance.items,
      'skipped': instance.skipped,
    };

KpiAreas _$KpiAreasFromJson(Map<String, dynamic> json) => KpiAreas(
  repair: json['repair'] == null
      ? null
      : KpiAreaScore.fromJson(json['repair'] as Map<String, dynamic>),
  maintenance: json['maintenance'] == null
      ? null
      : KpiAreaScore.fromJson(json['maintenance'] as Map<String, dynamic>),
  calibration: json['calibration'] == null
      ? null
      : KpiAreaScore.fromJson(json['calibration'] as Map<String, dynamic>),
);

Map<String, dynamic> _$KpiAreasToJson(KpiAreas instance) => <String, dynamic>{
  'repair': instance.repair?.toJson(),
  'maintenance': instance.maintenance?.toJson(),
  'calibration': instance.calibration?.toJson(),
};

KpiAreaWeights _$KpiAreaWeightsFromJson(Map<String, dynamic> json) =>
    KpiAreaWeights(
      repair: json['repair'] as num? ?? 0,
      maintenance: json['maintenance'] as num? ?? 0,
      calibration: json['calibration'] as num? ?? 0,
    );

Map<String, dynamic> _$KpiAreaWeightsToJson(KpiAreaWeights instance) =>
    <String, dynamic>{
      'repair': instance.repair,
      'maintenance': instance.maintenance,
      'calibration': instance.calibration,
    };

KpiWeights _$KpiWeightsFromJson(Map<String, dynamic> json) => KpiWeights(
  areaWeights: json['areaWeights'] == null
      ? const KpiAreaWeights()
      : KpiAreaWeights.fromJson(json['areaWeights'] as Map<String, dynamic>),
  metricWeights: json['metricWeights'] as Map<String, dynamic>? ?? const {},
  minItems: json['minItems'] as num? ?? 3,
  assistantWeight: json['assistantWeight'] as num? ?? 0.5,
  countBy: json['countBy'] as String? ?? 'completed',
);

Map<String, dynamic> _$KpiWeightsToJson(KpiWeights instance) =>
    <String, dynamic>{
      'areaWeights': instance.areaWeights.toJson(),
      'metricWeights': instance.metricWeights,
      'minItems': instance.minItems,
      'assistantWeight': instance.assistantWeight,
      'countBy': instance.countBy,
    };

KpiPoint _$KpiPointFromJson(Map<String, dynamic> json) => KpiPoint(
  type: json['type'] as String,
  start: json['start'] as String,
  end: json['end'] as String,
  total: json['total'] as num?,
  rank: json['rank'] as num?,
);

Map<String, dynamic> _$KpiPointToJson(KpiPoint instance) => <String, dynamic>{
  'type': instance.type,
  'start': instance.start,
  'end': instance.end,
  'total': instance.total,
  'rank': instance.rank,
};

KpiTaskItem _$KpiTaskItemFromJson(Map<String, dynamic> json) => KpiTaskItem(
  area: json['area'] as String,
  id: json['id'] as String,
  code: json['code'] as String,
  title: json['title'] as String,
  equipmentName: json['equipmentName'] as String?,
  departmentName: json['departmentName'] as String?,
  completedAt: json['completedAt'] as String?,
  onTime: json['onTime'] as bool? ?? true,
  quality: json['quality'] as num?,
);

Map<String, dynamic> _$KpiTaskItemToJson(KpiTaskItem instance) =>
    <String, dynamic>{
      'area': instance.area,
      'id': instance.id,
      'code': instance.code,
      'title': instance.title,
      'equipmentName': instance.equipmentName,
      'departmentName': instance.departmentName,
      'completedAt': instance.completedAt,
      'onTime': instance.onTime,
      'quality': instance.quality,
    };

KpiTaskPage _$KpiTaskPageFromJson(Map<String, dynamic> json) => KpiTaskPage(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => KpiTaskItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  total: json['total'] as num? ?? 0,
  page: json['page'] as num? ?? 1,
  limit: json['limit'] as num? ?? 20,
);

Map<String, dynamic> _$KpiTaskPageToJson(KpiTaskPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };

KpiPerson _$KpiPersonFromJson(Map<String, dynamic> json) => KpiPerson(
  userId: json['userId'] as String,
  fullName: json['fullName'] as String,
  inactive: json['inactive'] as bool? ?? false,
  type: json['type'] as String,
  start: json['start'] as String,
  end: json['end'] as String,
  total: json['total'] as num?,
  rank: json['rank'] as num?,
  insufficient: json['insufficient'] as bool? ?? false,
  credits: json['credits'] as num? ?? 0,
  items: json['items'] as num? ?? 0,
  onTime: json['onTime'] as num?,
  skipped: json['skipped'] as num? ?? 0,
  areas: json['areas'] == null
      ? const KpiAreas()
      : KpiAreas.fromJson(json['areas'] as Map<String, dynamic>),
  weights: json['weights'] == null
      ? const KpiWeights()
      : KpiWeights.fromJson(json['weights'] as Map<String, dynamic>),
  periods:
      (json['periods'] as List<dynamic>?)
          ?.map((e) => KpiPoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  tasks: json['tasks'] == null
      ? null
      : KpiTaskPage.fromJson(json['tasks'] as Map<String, dynamic>),
);

Map<String, dynamic> _$KpiPersonToJson(KpiPerson instance) => <String, dynamic>{
  'userId': instance.userId,
  'fullName': instance.fullName,
  'inactive': instance.inactive,
  'type': instance.type,
  'start': instance.start,
  'end': instance.end,
  'total': instance.total,
  'rank': instance.rank,
  'insufficient': instance.insufficient,
  'credits': instance.credits,
  'items': instance.items,
  'onTime': instance.onTime,
  'skipped': instance.skipped,
  'areas': instance.areas.toJson(),
  'weights': instance.weights.toJson(),
  'periods': instance.periods.map((e) => e.toJson()).toList(),
  'tasks': instance.tasks?.toJson(),
};

KpiTotals _$KpiTotalsFromJson(Map<String, dynamic> json) => KpiTotals(
  items: json['items'] as num? ?? 0,
  credits: json['credits'] as num? ?? 0,
  onTime: json['onTime'] as num?,
  avgHandleHours: json['avgHandleHours'] as num?,
  avgQuality: json['avgQuality'] as num?,
);

Map<String, dynamic> _$KpiTotalsToJson(KpiTotals instance) => <String, dynamic>{
  'items': instance.items,
  'credits': instance.credits,
  'onTime': instance.onTime,
  'avgHandleHours': instance.avgHandleHours,
  'avgQuality': instance.avgQuality,
};

KpiStaffRow _$KpiStaffRowFromJson(Map<String, dynamic> json) => KpiStaffRow(
  userId: json['userId'] as String,
  fullName: json['fullName'] as String,
  departmentId: json['departmentId'] as String?,
  inactive: json['inactive'] as bool? ?? false,
  total: json['total'] as num?,
  rank: json['rank'] as num?,
  rankChange: json['rankChange'] as num?,
  insufficient: json['insufficient'] as bool? ?? false,
  credits: json['credits'] as num? ?? 0,
  items: json['items'] as num? ?? 0,
  onTime: json['onTime'] as num?,
  avgHandleHours: json['avgHandleHours'] as num?,
  avgQuality: json['avgQuality'] as num?,
  skipped: json['skipped'] as num? ?? 0,
  areas: json['areas'] == null
      ? const KpiAreas()
      : KpiAreas.fromJson(json['areas'] as Map<String, dynamic>),
);

Map<String, dynamic> _$KpiStaffRowToJson(KpiStaffRow instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullName': instance.fullName,
      'departmentId': instance.departmentId,
      'inactive': instance.inactive,
      'total': instance.total,
      'rank': instance.rank,
      'rankChange': instance.rankChange,
      'insufficient': instance.insufficient,
      'credits': instance.credits,
      'items': instance.items,
      'onTime': instance.onTime,
      'avgHandleHours': instance.avgHandleHours,
      'avgQuality': instance.avgQuality,
      'skipped': instance.skipped,
      'areas': instance.areas.toJson(),
    };

KpiBoard _$KpiBoardFromJson(Map<String, dynamic> json) => KpiBoard(
  type: json['type'] as String,
  start: json['start'] as String,
  end: json['end'] as String,
  locked: json['locked'] as bool? ?? false,
  lockedBy: json['lockedBy'] as String?,
  lockedAt: json['lockedAt'] as String?,
  note: json['note'] as String?,
  weights: json['weights'] == null
      ? const KpiWeights()
      : KpiWeights.fromJson(json['weights'] as Map<String, dynamic>),
  totals: json['totals'] == null
      ? const KpiTotals()
      : KpiTotals.fromJson(json['totals'] as Map<String, dynamic>),
  staff:
      (json['staff'] as List<dynamic>?)
          ?.map((e) => KpiStaffRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$KpiBoardToJson(KpiBoard instance) => <String, dynamic>{
  'type': instance.type,
  'start': instance.start,
  'end': instance.end,
  'locked': instance.locked,
  'lockedBy': instance.lockedBy,
  'lockedAt': instance.lockedAt,
  'note': instance.note,
  'weights': instance.weights.toJson(),
  'totals': instance.totals.toJson(),
  'staff': instance.staff.map((e) => e.toJson()).toList(),
};

KpiPeriodItem _$KpiPeriodItemFromJson(Map<String, dynamic> json) =>
    KpiPeriodItem(
      type: json['type'] as String,
      start: json['start'] as String,
      end: json['end'] as String,
      locked: json['locked'] as bool? ?? false,
      lockedBy: json['lockedBy'] as String?,
      lockedAt: json['lockedAt'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$KpiPeriodItemToJson(KpiPeriodItem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'start': instance.start,
      'end': instance.end,
      'locked': instance.locked,
      'lockedBy': instance.lockedBy,
      'lockedAt': instance.lockedAt,
      'note': instance.note,
    };

KpiPeriods _$KpiPeriodsFromJson(Map<String, dynamic> json) => KpiPeriods(
  type: json['type'] as String,
  periods:
      (json['periods'] as List<dynamic>?)
          ?.map((e) => KpiPeriodItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$KpiPeriodsToJson(KpiPeriods instance) =>
    <String, dynamic>{
      'type': instance.type,
      'periods': instance.periods.map((e) => e.toJson()).toList(),
    };
