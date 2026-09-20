// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentView _$AttachmentViewFromJson(Map<String, dynamic> json) =>
    AttachmentView(
      id: json['id'] as String,
      fileId: json['fileId'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      kind: json['kind'] as String,
      label: json['label'] as String? ?? '',
      sortOrder: json['sortOrder'] as num? ?? 0,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      mime: json['mime'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: json['size'] as num? ?? 0,
    );

Map<String, dynamic> _$AttachmentViewToJson(AttachmentView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileId': instance.fileId,
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'kind': instance.kind,
      'label': instance.label,
      'sortOrder': instance.sortOrder,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt,
      'mime': instance.mime,
      'name': instance.name,
      'size': instance.size,
    };

PresignResult _$PresignResultFromJson(Map<String, dynamic> json) =>
    PresignResult(
      fileId: json['fileId'] as String,
      uploadUrl: json['uploadUrl'] as String,
      headers: json['headers'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$PresignResultToJson(PresignResult instance) =>
    <String, dynamic>{
      'fileId': instance.fileId,
      'uploadUrl': instance.uploadUrl,
      'headers': instance.headers,
    };

FileUrl _$FileUrlFromJson(Map<String, dynamic> json) =>
    FileUrl(url: json['url'] as String, expiresIn: json['expiresIn'] as num);

Map<String, dynamic> _$FileUrlToJson(FileUrl instance) => <String, dynamic>{
  'url': instance.url,
  'expiresIn': instance.expiresIn,
};
