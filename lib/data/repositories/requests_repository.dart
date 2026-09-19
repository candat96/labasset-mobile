import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/request.dart';
import '../models/request_detail.dart';

class RequestsRepository {
  RequestsRepository(this._dio);
  final Dio _dio;

  Future<RequestPage> list({
    String? q,
    String? status,
    bool pendingForMe = false,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.requests,
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (status != null && status.isNotEmpty) 'status': status,
        if (pendingForMe) 'pendingFor': 'me',
        'page': page,
        'limit': limit,
      },
    );
    return RequestPage.fromJson(res.data!);
  }

  Future<RequestDetail> detail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.request(id));
    return RequestDetail.fromJson(res.data!);
  }

  /// Duyệt (có thể chỉnh số lượng từng dòng; ghi chú khi duyệt 0).
  Future<void> approve(
    String id, {
    required List<({String itemId, String qtyApproved, String? note})> items,
    String? note,
  }) => _dio.post<void>(
    Ep.requestApprove(id),
    data: {
      'items': [
        for (final i in items)
          {
            'itemId': i.itemId,
            'qtyApproved': i.qtyApproved,
            if (i.note != null && i.note!.isNotEmpty) 'note': i.note,
          },
      ],
      'note': ?note,
    },
  );

  Future<void> reject(String id, String reason) =>
      _dio.post<void>(Ep.requestReject(id), data: {'reason': reason});

  Future<void> approveBulk(List<String> ids) =>
      _dio.post<void>(Ep.requestsApproveBulk, data: {'ids': ids});

  /// Cấp phát: tạo phiếu xuất draft (trả id phiếu xuất nếu API trả).
  Future<String?> issue(
    String id, {
    String? warehouseId,
    List<String> itemIds = const [],
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.requestIssue(id),
      data: {
        'warehouseId': ?warehouseId,
        if (itemIds.isNotEmpty) 'itemIds': itemIds,
      },
    );
    final data = res.data;
    if (data == null) return null;
    return (data['issueId'] ?? data['id']) as String?;
  }

  Future<List<RequestComment>> comments(String id) async {
    final res = await _dio.get<List<dynamic>>(Ep.requestComments(id));
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RequestComment.fromJson)
        .toList();
  }

  Future<void> addComment(String id, String body) =>
      _dio.post<void>(Ep.requestComments(id), data: {'body': body});
}
