import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/signing.dart';

/// `docType` dùng cho các endpoint ký của chứng từ (`/v1/documents/:docType/:id`).
class SigningDocType {
  SigningDocType._();

  static const repairCompletion = 'repair.completion';
  static const maintenanceTask = 'maintenance.task';
  static const calibrationResult = 'calibration.result';
  static const stockReceipt = 'stock.receipt';
  static const stockIssue = 'stock.issue';
  static const stocktakeResult = 'stocktake.result';
  static const demandProposal = 'demand.proposal';
}

/// Chữ ký số: hồ sơ theo tài khoản, tra chứng thư, ký và đọc bản đã ký.
class SigningRepository {
  SigningRepository(this._dio);
  final Dio _dio;

  /// `GET /v1/me/signing-profile`.
  Future<SigningProfileResponse> profile() async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.signingProfile);
    return SigningProfileResponse.fromJson(res.data!);
  }

  /// `PUT /v1/me/signing-profile` — mật khẩu rỗng nghĩa là giữ cũ; PIN chỉ gửi
  /// khi bật nhớ. Trả hồ sơ đã lưu (không kèm mật khẩu/PIN).
  Future<SigningProfile> save({
    required String username,
    required bool rememberPin,
    required String credentialId,
    required String certSerial,
    required String certSubject,
    required String certValidFrom,
    required String certValidTo,
    String? password,
    String? pin,
    String providerKey = 'intrust',
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      Ep.signingProfile,
      data: {
        'username': username,
        'rememberPin': rememberPin,
        'credentialId': credentialId,
        'certSerial': certSerial,
        'certSubject': certSubject,
        'certValidFrom': certValidFrom,
        'certValidTo': certValidTo,
        'providerKey': providerKey,
        if (password != null && password.isNotEmpty) 'password': password,
        if (rememberPin && pin != null && pin.isNotEmpty) 'pin': pin,
      },
    );
    return SigningProfile.fromJson(res.data!);
  }

  /// `POST /v1/me/signing-profile/session/clear` — buộc đăng nhập lại ở lần ký sau.
  Future<void> clearSession() => _dio.post<void>(Ep.signingProfileSessionClear);

  /// `GET /v1/signing/certificates?username=...`.
  Future<List<SigningCertificate>> certificates(String username) async {
    final res = await _dio.get<List<dynamic>>(
      Ep.signingCertificates,
      queryParameters: {'username': username},
    );
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SigningCertificate.fromJson)
        .toList();
  }

  /// `POST /v1/documents/:docType/:id/sign`.
  Future<SignResult> sign(
    String docType,
    String id, {
    required String slot,
    String? password,
    String? pin,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.documentSign(docType, id),
      data: {
        'slot': slot,
        if (password != null && password.isNotEmpty) 'password': password,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
      },
    );
    return SignResult.fromJson(res.data!);
  }

  /// `GET /v1/documents/:docType/:id/signed`.
  Future<List<SignedDocument>> signedDocuments(
    String docType,
    String id,
  ) async {
    final res = await _dio.get<List<dynamic>>(Ep.documentSigned(docType, id));
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SignedDocument.fromJson)
        .toList();
  }
}
