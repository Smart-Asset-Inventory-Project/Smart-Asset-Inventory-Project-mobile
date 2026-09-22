import 'package:dio/dio.dart';
import '../../models/transfer_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'user_directory.dart';

/// AST-FR-04: طلبات النقل والاعتماد.
/// pending -> approved/rejected فقط، لا حذف للسجل.
class TransferService {
  TransferService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<TransferModel>> fetchTransfers({String? status}) async {
    try {
      final res = await _api.get(AppConstants.transfersEndpoint,
          query: const {'limit': '200'});
      final body = Map<String, dynamic>.from(res.data as Map);
      var list = ((body['data'] as List? ?? []))
          .map((e) =>
              TransferModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // الباك اند بلا status: كل السجلات completed. فلترة الحالة محليا.
      if (status != null && status != 'all') {
        list = list.where((t) => t.status == status).toList();
      }
      // الأحدث أولا
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      // علم الدليل بالأسماء للعرض والاختيار (لا /users في الباك)
      final dir = UserDirectory.instance;
      for (final raw in (body['data'] as List? ?? [])) {
        final m = Map<String, dynamic>.from(raw as Map);
        dir.learnMap(m['fromUser'] as Map?);
        dir.learnMap(m['toUser'] as Map?);
      }
      return list;
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        return _mock();
      }
      rethrow;
    }
  }

  static final List<TransferModel> _mockTransfers = [
    const TransferModel(
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
    const TransferModel(
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

  /// POST /transfers: {assetId, toLocationId, toUserId?, reason?}.
  /// الباك اند يسجل النقل فوريا (completed) بلا اعتماد.
  Future<TransferModel> requestTransfer({
    required String assetId,
    required String toLocation,
    String? toCustodian,
    String? reason,
  }) async {
    try {
      final res = await _api.post(
        AppConstants.transfersEndpoint,
        data: {
          'assetId': assetId,
          'toLocationId': toLocation,
          if (toCustodian != null && toCustodian.isNotEmpty)
            'toUserId': toCustodian,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      final item = TransferModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
      _mockTransfers.insert(0, item);
      return item;
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        final item = TransferModel(
          id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
          assetId: assetId,
          assetTag: assetId,
          fromLocation: 'loc-b1-r101',
          toLocation: toLocation,
          toCustodian: toCustodian,
          status: 'pending',
          requestedBy: 'mock-user',
          requestedAt: DateTime.now().toIso8601String(),
          reason: reason,
        );
        _mockTransfers.insert(0, item);
        return item;
      }
      throw Exception(AuthService.backendMessage(e, 'Transfer failed'));
    }
  }

  Future<void> approveTransfer(String transferId, {String? decidedBy}) async {
    try {
      await _api.patch(
        '${AppConstants.transfersEndpoint}/$transferId/approve',
        data: {'status': 'approved'},
      );
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        final idx = _mockTransfers.indexWhere((t) => t.id == transferId);
        if (idx != -1) {
          final old = _mockTransfers[idx];
          _mockTransfers[idx] = TransferModel(
            id: old.id,
            assetId: old.assetId,
            assetTag: old.assetTag,
            fromLocation: old.fromLocation,
            toLocation: old.toLocation,
            fromCustodian: old.fromCustodian,
            toCustodian: old.toCustodian,
            status: 'approved',
            requestedBy: old.requestedBy,
            requestedAt: old.requestedAt,
            decidedBy: decidedBy ?? 'admin',
            decidedAt: DateTime.now().toIso8601String(),
          );
        }
        return;
      }
      rethrow;
    }
  }

  Future<void> rejectTransfer(String transferId, {String? decidedBy}) async {
    try {
      await _api.patch(
        '${AppConstants.transfersEndpoint}/$transferId/reject',
        data: {'status': 'rejected'},
      );
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        final idx = _mockTransfers.indexWhere((t) => t.id == transferId);
        if (idx != -1) {
          final old = _mockTransfers[idx];
          _mockTransfers[idx] = TransferModel(
            id: old.id,
            assetId: old.assetId,
            assetTag: old.assetTag,
            fromLocation: old.fromLocation,
            toLocation: old.toLocation,
            fromCustodian: old.fromCustodian,
            toCustodian: old.toCustodian,
            status: 'rejected',
            requestedBy: old.requestedBy,
            requestedAt: old.requestedAt,
            decidedBy: decidedBy ?? 'admin',
            decidedAt: DateTime.now().toIso8601String(),
          );
        }
        return;
      }
      rethrow;
    }
  }

  List<TransferModel> _mock() => List.from(_mockTransfers);
}
