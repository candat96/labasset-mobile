import 'package:dio/dio.dart';

import '../api/endpoints.dart';
import '../models/stock.dart';
import '../models/stock_extra.dart';
import '../models/stock_issue.dart';

class StockRepository {
  StockRepository(this._dio);
  final Dio _dio;

  Future<StockAlertPage> alerts({
    bool? resolved,
    String? type,
    String? supplyId,
    int page = 1,
    int limit = 20,
  }) async {
    final t = _nonEmpty(type);
    final sid = _nonEmpty(supplyId);
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.stockAlerts,
      queryParameters: {
        'resolved': ?resolved,
        'type': ?t,
        'supplyId': ?sid,
        'page': page,
        'limit': limit,
      },
    );
    return StockAlertPage.fromJson(res.data!);
  }

  Future<StockLotPage> lots({
    String? q,
    String? barcode,
    String? supplyId,
    String? warehouseId,
    String? status,
    bool? belowMin,
    int page = 1,
    int limit = 20,
  }) async {
    final query = _nonEmpty(q);
    final bar = _nonEmpty(barcode);
    final sid = _nonEmpty(supplyId);
    final wid = _nonEmpty(warehouseId);
    final st = _nonEmpty(status);
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.stockLots,
      queryParameters: {
        'q': ?query,
        'barcode': ?bar,
        'supplyId': ?sid,
        'warehouseId': ?wid,
        'status': ?st,
        'belowMin': ?belowMin,
        'page': page,
        'limit': limit,
      },
    );
    return StockLotPage.fromJson(res.data!);
  }

  /// Mở nắp lô (hoá chất): POST /v1/stock/lots/:id/open.
  Future<void> openLot(String id) => _dio.post<void>(Ep.stockLotOpen(id));

  /// Điều chỉnh tồn lô (ADM): POST /v1/stock/adjust.
  Future<void> adjust({
    required String lotId,
    required String newQty,
    required String reason,
  }) => _dio.post<void>(
    Ep.stockAdjust,
    data: {'lotId': lotId, 'newQty': newQty, 'reason': reason},
  );

  Future<StockForecast> forecast(String supplyId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.stockForecast,
      queryParameters: {'supplyId': supplyId},
    );
    return StockForecast.fromJson(res.data!);
  }

  // ── Nhập kho ───────────────────────────────────────────────
  Future<StockReceiptPage> receipts({
    String? q,
    String? status,
    String? warehouseId,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.stockReceipts,
      queryParameters: {
        'q': ?q,
        'status': ?status,
        'warehouseId': ?warehouseId,
        'page': page,
        'limit': limit,
      },
    );
    return StockReceiptPage.fromJson(res.data!);
  }

  Future<StockReceipt> receipt(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.stockReceipt(id));
    return StockReceipt.fromJson(res.data!);
  }

  Future<StockReceipt> createReceipt({
    required String type,
    required String warehouseId,
    String? supplierId,
    String? fromDepartmentId,
    String? invoiceNo,
    String? invoiceDate,
    String? receivedAt,
    String qcStatus = 'pending',
    String? qcNote,
    String? notes,
    required List<ReceiptItem> items,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.stockReceipts,
      data: {
        'type': type,
        'warehouseId': warehouseId,
        'supplierId': ?supplierId,
        'fromDepartmentId': ?fromDepartmentId,
        'invoiceNo': ?invoiceNo,
        'invoiceDate': ?invoiceDate,
        'receivedAt': ?receivedAt,
        'qcStatus': qcStatus,
        'qcNote': ?qcNote,
        'notes': ?notes,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );
    return StockReceipt.fromJson(res.data!);
  }

  Future<void> postReceipt(String id) =>
      _dio.post<void>(Ep.stockReceiptPost(id));

  Future<void> qcReceipt(String id, {required String status, String? note}) =>
      _dio.post<void>(
        Ep.stockReceiptQc(id),
        data: {'status': status, 'note': ?note},
      );

  Future<void> cancelReceipt(String id) =>
      _dio.post<void>(Ep.stockReceiptCancel(id));

  Future<List<int>> receiptPdf(String id) async {
    final res = await _dio.get<List<int>>(
      Ep.stockReceiptPdf(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  // ── Xuất kho ───────────────────────────────────────────────
  Future<StockIssuePage> issues({
    String? q,
    String? status,
    String? warehouseId,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      Ep.stockIssues,
      queryParameters: {
        'q': ?q,
        'status': ?status,
        'warehouseId': ?warehouseId,
        'page': page,
        'limit': limit,
      },
    );
    return StockIssuePage.fromJson(res.data!);
  }

  Future<StockIssue> issue(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(Ep.stockIssue(id));
    return StockIssue.fromJson(res.data!);
  }

  Future<StockIssue> createIssue({
    required String type,
    required String warehouseId,
    String? toDepartmentId,
    String? equipmentId,
    String? repairTicketId,
    String? maintenanceTaskId,
    String? receiverUserId,
    String? receiverName,
    String? reason,
    String? notes,
    required List<IssueItem> items,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.stockIssues,
      data: {
        'type': type,
        'warehouseId': warehouseId,
        'toDepartmentId': ?toDepartmentId,
        'equipmentId': ?equipmentId,
        'repairTicketId': ?repairTicketId,
        'maintenanceTaskId': ?maintenanceTaskId,
        'receiverUserId': ?receiverUserId,
        'receiverName': ?receiverName,
        'reason': ?reason,
        'notes': ?notes,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );
    return StockIssue.fromJson(res.data!);
  }

  /// Xuất nhanh 1 bước (`POST /v1/stock/issues/quick`) — tự ghi sổ.
  Future<StockIssue> quickIssue({
    required String type,
    required String warehouseId,
    String? toDepartmentId,
    String? equipmentId,
    String? reason,
    required List<IssueItem> items,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      Ep.stockIssuesQuick,
      data: {
        'type': type,
        'warehouseId': warehouseId,
        'toDepartmentId': ?toDepartmentId,
        'equipmentId': ?equipmentId,
        'reason': ?reason,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );
    return StockIssue.fromJson(res.data!);
  }

  Future<void> updateIssue(String id, Map<String, dynamic> data) =>
      _dio.patch<void>(Ep.stockIssue(id), data: data);

  Future<void> postIssue(String id) => _dio.post<void>(Ep.stockIssuePost(id));

  Future<void> cancelIssue(String id) =>
      _dio.post<void>(Ep.stockIssueCancel(id));

  Future<List<LotSuggestion>> suggestLots({
    required String supplyId,
    required String warehouseId,
    required String quantity,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      Ep.stockIssueSuggestLots,
      queryParameters: {
        'supplyId': supplyId,
        'warehouseId': warehouseId,
        'quantity': quantity,
      },
    );
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LotSuggestion.fromJson)
        .toList();
  }

  Future<List<int>> issuePdf(String id) async {
    final res = await _dio.get<List<int>>(
      Ep.stockIssuePdf(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  // ── Chuyển kho ─────────────────────────────────────────────
  Future<void> createTransfer({
    required String fromWarehouseId,
    required String toWarehouseId,
    required List<({String lotId, String quantity})> items,
  }) => _dio.post<void>(
    Ep.stockTransfers,
    data: {
      'fromWarehouseId': fromWarehouseId,
      'toWarehouseId': toWarehouseId,
      'items': [
        for (final i in items) {'lotId': i.lotId, 'quantity': i.quantity},
      ],
    },
  );

  Future<void> resolveAlert(String id) =>
      _dio.post<void>(Ep.stockAlertResolve(id));
}

String? _nonEmpty(String? v) => v == null || v.isEmpty ? null : v;
