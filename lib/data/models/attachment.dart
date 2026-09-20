import 'package:json_annotation/json_annotation.dart';

part 'attachment.g.dart';

/// `GET/POST /v1/attachments` → AttachmentViewDto (B6-B13 có mime/name/size).
@JsonSerializable()
class AttachmentView {
  const AttachmentView({
    required this.id,
    required this.fileId,
    required this.entityType,
    required this.entityId,
    required this.kind,
    this.label = '',
    this.sortOrder = 0,
    this.createdBy = '',
    this.createdAt,
    this.mime = '',
    this.name = '',
    this.size = 0,
  });

  final String id;
  final String fileId;
  final String entityType;
  final String entityId;
  final String kind;
  final String label;
  final num sortOrder;
  final String createdBy;
  final String? createdAt;
  final String mime;
  final String name;
  final num size;

  /// Tên hiển thị ưu tiên `label`, sau đó `name` từ file.
  String get displayName => label.isNotEmpty ? label : name;

  bool get isImage =>
      mime.startsWith('image/') ||
      kind == 'photo' ||
      name.toLowerCase().endsWith('.png') ||
      name.toLowerCase().endsWith('.jpg') ||
      name.toLowerCase().endsWith('.jpeg') ||
      name.toLowerCase().endsWith('.webp');

  factory AttachmentView.fromJson(Map<String, dynamic> json) =>
      _$AttachmentViewFromJson(json);
  Map<String, dynamic> toJson() => _$AttachmentViewToJson(this);
}

/// `POST /v1/files/presign` → PresignResultDto.
@JsonSerializable()
class PresignResult {
  const PresignResult({
    required this.fileId,
    required this.uploadUrl,
    this.headers = const {},
  });

  final String fileId;
  final String uploadUrl;
  final Map<String, dynamic> headers;

  factory PresignResult.fromJson(Map<String, dynamic> json) =>
      _$PresignResultFromJson(json);
  Map<String, dynamic> toJson() => _$PresignResultToJson(this);
}

/// `GET /v1/files/{id}/url` → FileUrlDto.
@JsonSerializable()
class FileUrl {
  const FileUrl({required this.url, required this.expiresIn});

  final String url;
  final num expiresIn;

  factory FileUrl.fromJson(Map<String, dynamic> json) =>
      _$FileUrlFromJson(json);
  Map<String, dynamic> toJson() => _$FileUrlToJson(this);
}
