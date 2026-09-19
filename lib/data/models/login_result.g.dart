// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResult _$LoginResultFromJson(Map<String, dynamic> json) => LoginResult(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  tenantId: json['tenantId'] as String,
  user: UserView.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LoginResultToJson(LoginResult instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'tenantId': instance.tenantId,
      'user': instance.user,
    };

OtpChallenge _$OtpChallengeFromJson(Map<String, dynamic> json) => OtpChallenge(
  otpRequired: json['otpRequired'] as bool,
  otpToken: json['otpToken'] as String,
);

Map<String, dynamic> _$OtpChallengeToJson(OtpChallenge instance) =>
    <String, dynamic>{
      'otpRequired': instance.otpRequired,
      'otpToken': instance.otpToken,
    };
