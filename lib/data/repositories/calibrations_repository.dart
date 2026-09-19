import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/maintenance.dart';

class CalibrationsRepository {
  CalibrationsRepository(this._dio);
  final Dio _dio;

  Future<CalibrationPage> list({
    String? equipmentId,
    String? status,
    String? result,
    String? dueBefore,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.calibrations,
      queryParameters: {
        'equipmentId': ?equipmentId,
        'status': ?status,
        'result': ?result,
        'dueBefore': ?dueBefore,
        'type': ?type,
        'page': page,
        'limit': limit,
      },
    );
    return CalibrationPage.fromJson(res.data!);
  }

  Future<Calibration> create({
    required String equipmentId,
    required String type,
    String? scheduledAt,
    String? performedAt,
    String? agencyId,
    String? performerName,
    String? result,
    String? certificateNo,
    String? certificateFileId,
    String? findings,
    String? cost,
    num? cycleMonths,
    String? nextDueAt,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.calibrations,
      data: {
        'equipmentId': equipmentId,
        'type': type,
        'scheduledAt': ?scheduledAt,
        'performedAt': ?performedAt,
        'agencyId': ?agencyId,
        'performerName': ?performerName,
        'result': ?result,
        'certificateNo': ?certificateNo,
        'certificateFileId': ?certificateFileId,
        'findings': ?findings,
        'cost': ?cost,
        'cycleMonths': ?cycleMonths,
        'nextDueAt': ?nextDueAt,
      },
    );
    return Calibration.fromJson(res.data!);
  }

  Future<void> complete(
    String id, {
    required String performedAt,
    required String result,
    String? agencyId,
    String? performerName,
    String? certificateNo,
    String? certificateFileId,
    String? findings,
    String? cost,
    num? cycleMonths,
    String? nextDueAt,
  }) => _dio.post<void>(
    Ep.calibrationComplete(id),
    data: {
      'performedAt': performedAt,
      'result': result,
      'agencyId': ?agencyId,
      'performerName': ?performerName,
      'certificateNo': ?certificateNo,
      'certificateFileId': ?certificateFileId,
      'findings': ?findings,
      'cost': ?cost,
      'cycleMonths': ?cycleMonths,
      'nextDueAt': ?nextDueAt,
    },
  );
}
