import 'package:dio/dio.dart';
import '../../models/transfer_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-04: طلبات النقل والاعتماد.
/// pending -> approved/rejected فقط، لا حذف للسجل.
class TransferService {
  TransferService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<TransferModel>> fetchTransfers({String? status}) async {
    try {
      final res = await _api.get(AppConstants.transfersEndpoint,
          query: {if (status != null) 'status': status});
      final raw = res.data is List
          ? res.data as List
          : (res.data['data'] as List? ?? []);
      return raw
          .map((e) =>
              TransferModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return _mock();
      }
      rethrow;
    }
  }

  Future<TransferModel> requestTransfer({
    required String assetId,
    required String toLocation,
    String? toCustodian,
  }) async {
    try {
      final res = await _api.post(
        AppConstants.transfersEndpoint,
        data: {
          'assetId': assetId,
          'toLocation': toLocation,
          if (toCustodian != null) 'toCustodian': toCustodian,
        },
      );
      final data = res.data is Map ? res.data['data'] ?? res.data : {};
      return TransferModel.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        // mock accept محلي حتى يجهز الباك اند
        return TransferModel(
          id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
          assetId: assetId,
          assetTag: assetId,
          fromLocation: 'loc-b1-r101',
          toLocation: toLocation,
          toCustodian: toCustodian,
          status: 'pending',
          requestedBy: 'mock-user',
          requestedAt: DateTime.now().toIso8601String(),
        );
      }
      rethrow;
    }
  }

  List<TransferModel> _mock() => [
        TransferModel(
          id: 't1',
          assetId: 'mock-3',
          assetTag: 'AST-B1-1003',
          fromLocation: 'loc-b1-r101',
          toLocation: 'loc-b2-r201',
          fromCustodian: 'user-1',
          toCustodian: 'user-2',
          status: 'pending',
          requestedBy: 'user-1',
          requestedAt: '2026-09-18T10:00:00Z',
        ),
        TransferModel(
          id: 't2',
          assetId: 'mock-5',
          assetTag: 'AST-B1-1005',
          fromLocation: 'loc-b1-r102',
          toLocation: 'loc-b1-r103',
          status: 'approved',
          requestedBy: 'user-2',
          requestedAt: '2026-09-15T09:00:00Z',
          decidedBy: 'admin-1',
          decidedAt: '2026-09-16T09:00:00Z',
        ),
      ];
}
