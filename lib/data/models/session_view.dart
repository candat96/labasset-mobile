import 'package:json_annotation/json_annotation.dart';

part 'session_view.g.dart';

@JsonSerializable()
class SessionView {
  const SessionView({
    required this.id,
    this.deviceInfo,
    this.ip,
    required this.createdAt,
    this.lastUsedAt,
    required this.expiresAt,
  });

  final String id;
  final String? deviceInfo;
  final String? ip;
  final String createdAt;
  final String? lastUsedAt;
  final String expiresAt;

  factory SessionView.fromJson(Map<String, dynamic> json) =>
      _$SessionViewFromJson(json);
  Map<String, dynamic> toJson() => _$SessionViewToJson(this);
}
