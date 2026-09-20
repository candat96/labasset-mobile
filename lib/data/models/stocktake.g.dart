// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stocktake.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StocktakeSession _$StocktakeSessionFromJson(Map<String, dynamic> json) =>
    StocktakeSession(
      id: json['id'] as String,
      code: json['code'] as String,
      type: json['type'] as String? ?? 'equipment',
      scopeType: json['scopeType'] as String? ?? 'all',
      scopeId: json['scopeId'] as String?,
      name: json['name'] as String? ?? '',
      plannedAt: json['plannedAt'] as String?,
      status: json['status'] as String? ?? 'open',
      assignments:
          (json['assignments'] as List<dynamic>?)
              ?.map(
                (e) => StocktakeAssignment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      total: json['total'] as num? ?? 0,
      counted: json['counted'] as num? ?? 0,
      diff: json['diff'] as num? ?? 0,
    );

Map<String, dynamic> _$StocktakeSessionToJson(StocktakeSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'type': instance.type,
      'scopeType': instance.scopeType,
      'scopeId': instance.scopeId,
      'name': instance.name,
      'plannedAt': instance.plannedAt,
      'status': instance.status,
      'assignments': instance.assignments,
      'total': instance.total,
      'counted': instance.counted,
      'diff': instance.diff,
    };

StocktakeAssignment _$StocktakeAssignmentFromJson(Map<String, dynamic> json) =>
    StocktakeAssignment(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String?,
      subScope: json['subScope'] as Map<String, dynamic>?,
      progress: json['progress'] as num? ?? 0,
    );

Map<String, dynamic> _$StocktakeAssignmentToJson(
  StocktakeAssignment instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'fullName': instance.fullName,
  'subScope': instance.subScope,
  'progress': instance.progress,
};

StocktakePage _$StocktakePageFromJson(Map<String, dynamic> json) =>
    StocktakePage(
      items: (json['items'] as List<dynamic>)
          .map((e) => StocktakeSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num? ?? 0,
    );

Map<String, dynamic> _$StocktakePageToJson(StocktakePage instance) =>
    <String, dynamic>{'items': instance.items, 'total': instance.total};

StocktakePackageItem _$StocktakePackageItemFromJson(
  Map<String, dynamic> json,
) => StocktakePackageItem(
  itemId: json['itemId'] as String,
  equipmentId: json['equipmentId'] as String?,
  lotId: json['lotId'] as String?,
  supplyId: json['supplyId'] as String?,
  code: json['code'] as String,
  name: json['name'] as String,
  location: json['location'] as String?,
  lotNo: json['lotNo'] as String?,
  bookQty: json['bookQty'] as String? ?? '1',
  qrToken: json['qrToken'] as String?,
  supplyCode: json['supplyCode'] as String?,
  manufacturerCode: json['manufacturerCode'] as String?,
);

Map<String, dynamic> _$StocktakePackageItemToJson(
  StocktakePackageItem instance,
) => <String, dynamic>{
  'itemId': instance.itemId,
  'equipmentId': instance.equipmentId,
  'lotId': instance.lotId,
  'supplyId': instance.supplyId,
  'code': instance.code,
  'name': instance.name,
  'location': instance.location,
  'lotNo': instance.lotNo,
  'bookQty': instance.bookQty,
  'qrToken': instance.qrToken,
  'supplyCode': instance.supplyCode,
  'manufacturerCode': instance.manufacturerCode,
};

StocktakeProgress _$StocktakeProgressFromJson(Map<String, dynamic> json) =>
    StocktakeProgress(
      total: json['total'] as num? ?? 0,
      counted: json['counted'] as num? ?? 0,
      percent: json['percent'] as num? ?? 0,
    );

Map<String, dynamic> _$StocktakeProgressToJson(StocktakeProgress instance) =>
    <String, dynamic>{
      'total': instance.total,
      'counted': instance.counted,
      'percent': instance.percent,
    };

StocktakeConflict _$StocktakeConflictFromJson(Map<String, dynamic> json) =>
    StocktakeConflict(
      clientId: json['clientId'] as String,
      itemId: json['itemId'] as String?,
      keptCountedAt: json['keptCountedAt'] as String?,
    );

Map<String, dynamic> _$StocktakeConflictToJson(StocktakeConflict instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'itemId': instance.itemId,
      'keptCountedAt': instance.keptCountedAt,
    };
