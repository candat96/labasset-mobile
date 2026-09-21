import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/demand.dart';

/// Dự trù (E1a) — `/v1/demand/*`. Số lượng/tiền là chuỗi numeric(18,4).
class DemandRepository {
  DemandRepository(this._dio);
  final Dio _dio;

  /// `/v1/demand/my` — phiếu khoa trong kỳ đang mở (ADM/VT: toàn viện).
  Future<DemandRequestPage> my({
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.demandMy,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return DemandRequestPage.fromJson(res.data!);
  }

  /// `/v1/demand/periods` — lọc `status` (csv) và `year`.
  Future<DemandPeriodPage> periods({
    String? status,
    int? year,
    int page = 1,
    int limit = 30,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.demandPeriods,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'year': ?year,
        'page': page,
        'limit': limit,
      },
    );
    return DemandPeriodPage.fromJson(res.data!);
  }

  Future<DemandPeriod> period(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.demandPeriod(id));
    return DemandPeriod.fromJson(res.data!);
  }

  /// `/v1/demand/periods/:id/requests` — danh sách phiếu khoa + tiến độ.
  Future<DemandRequestSummaryPage> periodRequests(
    String id, {
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.demandPeriodRequests(id),
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return DemandRequestSummaryPage.fromJson(res.data!);
  }

  Future<DemandRequest> request(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.demandRequest(id));
    return DemandRequest.fromJson(res.data!);
  }

  /// Trưởng khoa duyệt phiếu (ADM cũng gọi được).
  Future<DemandRequest> deptApprove(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.demandRequestDeptApprove(id),
    );
    return DemandRequest.fromJson(res.data!);
  }

  /// Trả lại phiếu (lý do bắt buộc).
  Future<DemandRequest> returnRequest(String id, String reason) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.demandRequestReturn(id),
      data: {'reason': reason},
    );
    return DemandRequest.fromJson(res.data!);
  }

  /// VT tiếp nhận; `lines` bỏ trống = duyệt toàn bộ theo `qtyRequested`.
  Future<DemandRequest> accept(
    String id, {
    List<({String id, String qtyApproved, String? approverNote})>? lines,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.demandRequestAccept(id),
      data: {
        if (lines != null)
          'lines': [
            for (final l in lines)
              {
                'id': l.id,
                'qtyApproved': l.qtyApproved,
                if (l.approverNote != null && l.approverNote!.isNotEmpty)
                  'approverNote': l.approverNote,
              },
          ],
      },
    );
    return DemandRequest.fromJson(res.data!);
  }

  /// Bảng gộp toàn viện của kỳ (chỉ khi đã tổng hợp).
  Future<List<DemandConsolidation>> consolidation(String periodId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.demandPeriodConsolidation(periodId),
    );
    return DemandConsolidationList.fromJson(res.data!).items;
  }

  Future<DemandSummary> summary(String periodId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.demandPeriodSummary(periodId),
    );
    return DemandSummary.fromJson(res.data!);
  }
}
