import 'package:json_annotation/json_annotation.dart';

import 'user_view.dart';

part 'login_result.g.dart';

@JsonSerializable()
class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tenantId;
  final UserView user;

  factory LoginResult.fromJson(Map<String, dynamic> json) =>
      _$LoginResultFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResultToJson(this);
}

@JsonSerializable()
class OtpChallenge {
  const OtpChallenge({required this.otpRequired, required this.otpToken});

  final bool otpRequired;
  final String otpToken;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) =>
      _$OtpChallengeFromJson(json);
  Map<String, dynamic> toJson() => _$OtpChallengeToJson(this);
}

/// Kết quả `POST /v1/auth/login`: token hoặc yêu cầu OTP.
sealed class LoginOutcome {
  const LoginOutcome();

  static LoginOutcome fromJson(Map<String, dynamic> json) {
    if (json['otpRequired'] == true)
      return OtpRequired(OtpChallenge.fromJson(json));
    return LoggedIn(LoginResult.fromJson(json));
  }
}

class LoggedIn extends LoginOutcome {
  const LoggedIn(this.result);
  final LoginResult result;
}

class OtpRequired extends LoginOutcome {
  const OtpRequired(this.challenge);
  final OtpChallenge challenge;
}
