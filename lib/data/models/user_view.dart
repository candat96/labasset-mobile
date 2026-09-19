import 'package:json_annotation/json_annotation.dart';

part 'user_view.g.dart';

@JsonSerializable()
class UserView {
  const UserView({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    this.departmentId,
    this.roles = const [],
    this.mustChangePassword = false,
    this.otpEnabled = false,
  });

  final String id;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final String? departmentId;
  @JsonKey(defaultValue: <String>[])
  final List<String> roles;
  @JsonKey(defaultValue: false)
  final bool mustChangePassword;
  @JsonKey(defaultValue: false)
  final bool otpEnabled;

  factory UserView.fromJson(Map<String, dynamic> json) =>
      _$UserViewFromJson(json);
  Map<String, dynamic> toJson() => _$UserViewToJson(this);
}
