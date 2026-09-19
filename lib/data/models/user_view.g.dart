// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserView _$UserViewFromJson(Map<String, dynamic> json) => UserView(
  id: json['id'] as String,
  username: json['username'] as String,
  fullName: json['fullName'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  departmentId: json['departmentId'] as String?,
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  otpEnabled: json['otpEnabled'] as bool? ?? false,
);

Map<String, dynamic> _$UserViewToJson(UserView instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'fullName': instance.fullName,
  'email': instance.email,
  'phone': instance.phone,
  'departmentId': instance.departmentId,
  'roles': instance.roles,
  'mustChangePassword': instance.mustChangePassword,
  'otpEnabled': instance.otpEnabled,
};
