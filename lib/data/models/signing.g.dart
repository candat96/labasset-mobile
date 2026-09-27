// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SigningProfile _$SigningProfileFromJson(Map<String, dynamic> json) =>
    SigningProfile(
      userId: json['userId'] as String,
      providerKey: json['providerKey'] as String,
      username: json['username'] as String,
      credentialId: json['credentialId'] as String,
      certSerial: json['certSerial'] as String,
      certSubject: json['certSubject'] as String,
      certValidFrom: json['certValidFrom'] as String,
      certValidTo: json['certValidTo'] as String,
      sessionExpiresAt: json['sessionExpiresAt'] as String?,
      rememberPin: json['rememberPin'] as bool,
      expiringSoon: json['expiringSoon'] as bool,
      passwordSet: json['passwordSet'] as bool,
      pinSet: json['pinSet'] as bool,
    );

Map<String, dynamic> _$SigningProfileToJson(SigningProfile instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'providerKey': instance.providerKey,
      'username': instance.username,
      'credentialId': instance.credentialId,
      'certSerial': instance.certSerial,
      'certSubject': instance.certSubject,
      'certValidFrom': instance.certValidFrom,
      'certValidTo': instance.certValidTo,
      'sessionExpiresAt': instance.sessionExpiresAt,
      'rememberPin': instance.rememberPin,
      'expiringSoon': instance.expiringSoon,
      'passwordSet': instance.passwordSet,
      'pinSet': instance.pinSet,
    };

SigningProfileResponse _$SigningProfileResponseFromJson(
  Map<String, dynamic> json,
) => SigningProfileResponse(
  profile: json['profile'] == null
      ? null
      : SigningProfile.fromJson(json['profile'] as Map<String, dynamic>),
  configured: json['configured'] as bool,
);

Map<String, dynamic> _$SigningProfileResponseToJson(
  SigningProfileResponse instance,
) => <String, dynamic>{
  'profile': instance.profile,
  'configured': instance.configured,
};

SigningCertificate _$SigningCertificateFromJson(Map<String, dynamic> json) =>
    SigningCertificate(
      keyId: json['keyId'] as String,
      serial: json['serial'] as String,
      subject: json['subject'] as String,
      displayName: json['displayName'] as String,
      provider: json['provider'] as String,
      validFrom: json['validFrom'] as String,
      validTo: json['validTo'] as String,
    );

Map<String, dynamic> _$SigningCertificateToJson(SigningCertificate instance) =>
    <String, dynamic>{
      'keyId': instance.keyId,
      'serial': instance.serial,
      'subject': instance.subject,
      'displayName': instance.displayName,
      'provider': instance.provider,
      'validFrom': instance.validFrom,
      'validTo': instance.validTo,
    };

SignResult _$SignResultFromJson(Map<String, dynamic> json) => SignResult(
  fileId: json['fileId'] as String,
  attachmentId: json['attachmentId'] as String,
);

Map<String, dynamic> _$SignResultToJson(SignResult instance) =>
    <String, dynamic>{
      'fileId': instance.fileId,
      'attachmentId': instance.attachmentId,
    };

SignedDocument _$SignedDocumentFromJson(Map<String, dynamic> json) =>
    SignedDocument(
      attachmentId: json['attachmentId'] as String,
      fileId: json['fileId'] as String,
      name: json['name'] as String,
      label: json['label'] as String?,
      signedAt: json['signedAt'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$SignedDocumentToJson(SignedDocument instance) =>
    <String, dynamic>{
      'attachmentId': instance.attachmentId,
      'fileId': instance.fileId,
      'name': instance.name,
      'label': instance.label,
      'signedAt': instance.signedAt,
      'url': instance.url,
    };
