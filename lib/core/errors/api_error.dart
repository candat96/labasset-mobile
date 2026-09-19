import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

/// Lỗi chuẩn của API `{ code, message, details? }`.
class ApiError implements Exception {
  ApiError(this.status, this.code, this.message, [this.details]);

  final int status;
  final String code;
  final String message;
  final Object? details;

  static ApiError fromResponse(Response<dynamic>? res) {
    final status = res?.statusCode ?? 0;
    final data = res?.data;
    if (data is Map && data['code'] is String) {
      return ApiError(
        status,
        data['code'] as String,
        (data['message'] as String?) ?? data['code'] as String,
        data['details'],
      );
    }
    return ApiError(
      status,
      'HTTP_$status',
      res?.statusMessage ?? 'HTTP $status',
    );
  }

  static ApiError from(Object e) {
    if (e is ApiError) return e;
    if (e is DioException) {
      if (e.response != null) return fromResponse(e.response);
      return ApiError(0, 'NETWORK_ERROR', e.message ?? 'network');
    }
    return ApiError(0, 'UNKNOWN', e.toString());
  }

  /// Thông điệp hiển thị: ưu tiên i18n theo `code`, không có thì `message`.
  static String messageFor(Object e) {
    final err = from(e);
    final key = 'errors.${err.code}';
    final translated = key.tr;
    if (translated != key) return translated;
    return err.message.isNotEmpty ? err.message : 'errors.UNKNOWN'.tr;
  }

  /// `VALIDATION_ERROR.details` là `string[]` kiểu class-validator → map field → message.
  Map<String, String> fieldErrors() {
    final out = <String, String>{};
    final d = details;
    if (d is List) {
      for (final item in d) {
        if (item is String) {
          final field = item.split(RegExp(r'\s+')).first;
          out.putIfAbsent(field, () => item);
        } else if (item is Map && item['field'] is String) {
          out[item['field'] as String] = (item['message'] as String?) ?? '';
        }
      }
    } else if (d is Map) {
      d.forEach((k, v) => out[k.toString()] = v.toString());
    }
    return out;
  }

  @override
  String toString() => 'ApiError($status $code: $message)';
}
