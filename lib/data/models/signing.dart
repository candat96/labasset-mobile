import 'package:json_annotation/json_annotation.dart';

part 'signing.g.dart';

/// Hồ sơ chữ ký số của chính người đang đăng nhập. API **không bao giờ** trả
/// mật khẩu hay PIN — chỉ hai cờ [passwordSet] / [pinSet] cho biết đã lưu chưa.
@JsonSerializable()
class SigningProfile {
  const SigningProfile({
    required this.userId,
    required this.providerKey,
    required this.username,
    required this.credentialId,
    required this.certSerial,
    required this.certSubject,
    required this.certValidFrom,
    required this.certValidTo,
    this.sessionExpiresAt,
    required this.rememberPin,
    required this.expiringSoon,
    required this.passwordSet,
    required this.pinSet,
  });

  final String userId;
  final String providerKey;
  final String username;
  final String credentialId;
  final String certSerial;
  final String certSubject;
  final String certValidFrom;
  final String certValidTo;
  final String? sessionExpiresAt;
  final bool rememberPin;
  final bool expiringSoon;
  final bool passwordSet;
  final bool pinSet;

  /// Chứng thư đã hết hạn theo thời điểm hiện tại.
  bool get expired {
    final to = DateTime.tryParse(certValidTo);
    return to != null && !to.isAfter(DateTime.now());
  }

  factory SigningProfile.fromJson(Map<String, dynamic> json) =>
      _$SigningProfileFromJson(json);
  Map<String, dynamic> toJson() => _$SigningProfileToJson(this);
}

/// `GET /v1/me/signing-profile` — hồ sơ (null khi chưa cài) + cờ cấu hình viện.
@JsonSerializable()
class SigningProfileResponse {
  const SigningProfileResponse({this.profile, required this.configured});

  final SigningProfile? profile;
  final bool configured;

  factory SigningProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$SigningProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SigningProfileResponseToJson(this);
}

/// Một chứng thư tra được từ nhà cung cấp (`GET /v1/signing/certificates`).
@JsonSerializable()
class SigningCertificate {
  const SigningCertificate({
    required this.keyId,
    required this.serial,
    required this.subject,
    required this.displayName,
    required this.provider,
    required this.validFrom,
    required this.validTo,
  });

  final String keyId;
  final String serial;
  final String subject;
  final String displayName;
  final String provider;
  final String validFrom;
  final String validTo;

  bool get expired {
    final to = DateTime.tryParse(validTo);
    return to != null && !to.isAfter(DateTime.now());
  }

  bool get expiringSoon {
    final to = DateTime.tryParse(validTo);
    if (to == null) return false;
    final left = to.difference(DateTime.now());
    return left > Duration.zero && left <= const Duration(days: 30);
  }

  factory SigningCertificate.fromJson(Map<String, dynamic> json) =>
      _$SigningCertificateFromJson(json);
  Map<String, dynamic> toJson() => _$SigningCertificateToJson(this);
}

/// Kết quả một lệnh ký.
@JsonSerializable()
class SignResult {
  const SignResult({required this.fileId, required this.attachmentId});

  final String fileId;
  final String attachmentId;

  factory SignResult.fromJson(Map<String, dynamic> json) =>
      _$SignResultFromJson(json);
  Map<String, dynamic> toJson() => _$SignResultToJson(this);
}

/// Một bản đã ký của chứng từ, kèm [url] tải về có hạn.
@JsonSerializable()
class SignedDocument {
  const SignedDocument({
    required this.attachmentId,
    required this.fileId,
    required this.name,
    this.label,
    required this.signedAt,
    required this.url,
  });

  final String attachmentId;
  final String fileId;
  final String name;
  final String? label;
  final String signedAt;
  final String url;

  factory SignedDocument.fromJson(Map<String, dynamic> json) =>
      _$SignedDocumentFromJson(json);
  Map<String, dynamic> toJson() => _$SignedDocumentToJson(this);
}
