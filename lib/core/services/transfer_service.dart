import 'package:dio/dio.dart';
import '../../models/transfer_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'user_directory.dart';

/// AST-FR-04: طلبات النقل والاعتماد.
/// pending -> approved/rejected فقط، لا حذف للسجل.
class TransferService {
  TransferService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<TransferModel>> fetchTransfers(
      {String? status, String? assetId, String? scopeLocationId}) async {
    try {
      final res = await _api.get(AppConstants.transfersEndpoint, query: {
        'limit': '${AppConstants.pageSize}',
        if (assetId != null && assetId.isNotEmpty) 'assetId': assetId,
      });
      final body = Map<String, dynamic>.from(res.data as Map);
      var list = <TransferModel>[];
      for (final e in (body['data'] as List? ?? [])) {
        try {
          if (e is Map) {
            list.add(TransferModel.fromJson(
                Map<String, dynamic>.from(e)));
          }
        } catch (_) {}
      }
      // الباك اند بلا status: كل السجلات completed. فلترة الحالة محليا.
      if (status != null && status != 'all') {
        list = list.where((t) => t.status == status).toList();
      }
      // Scope-Based: الكاستوديان يرى نقل نطاقه فقط (from أو to داخل الشجرة).
      if (scopeLocationId != null && scopeLocationId.isNotEmpty) {
        try {
          final locs = await LocationService(api: _api).fetchLocations();
          final scope = LocationService.subtreeIds(locs, scopeLocationId);
          list = list
              .where((t) =>
                  scope.contains(t.fromLocation) ||
                  scope.contains(t.toLocation))
              .toList();
        } catch (_) {
          // لو المواقع فشلت يعرض الكل بدلا من شاشة فاضية
        }
      }
      // الأحدث أولا
      list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      // علم الدليل بالأسماء للعرض والاختيار (لا /users في الباك).
      // الأشكال غير المضمونة (scalar id) تُتجاهل بأمان بدل ما توقع الجلب.
      final dir = UserDirectory.instance;
      for (final raw in (body['data'] as List? ?? [])) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        dir.learnDynamic(m['fromUser']);
        dir.learnDynamic(m['toUser']);
      }
      return list;
    } on DioException catch (_) {
      if (AppConstants.allowMockFallback) {
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

  /// POST /transfers: {assetId, toLocationId, reason?}.
  /// Docs: source location + actor derived server-side, atomic inventory
  /// update. Same-location fails (400). No toUserId — custody is separate.
  /// toCustodian kept for mock/dev only and never sent to backend.
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
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      final item = TransferModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
      _mockTransfers.insert(0, item);
      return item;
    } on DioException catch (e) {
      // Mock فقط للباك الميت. 403 تظهر برقمها (تروح outbox)،
      // وباقي الرفض الحقيقي يظهر كما هو.
      final code = e.response?.statusCode;
      if (AppConstants.allowMockFallback && (code == null || code >= 500)) {
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
      final msg = AuthService.backendMessage(e, 'Transfer failed');
      throw Exception(code != null ? '$msg ($code)' : msg);
    }
  }

  /// No backend approval workflow: transfers complete immediately.
  /// Kept for dev-mock only; production callers should not use it.
  Future<void> approveTransfer(String transferId, {String? decidedBy}) async {
    if (AppConstants.allowMockFallback) {
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
    throw Exception('Transfers complete immediately — no approval step');
  }

  Future<void> rejectTransfer(String transferId, {String? decidedBy}) async {
    if (AppConstants.allowMockFallback) {
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
    throw Exception('Transfers complete immediately — no rejection step');
  }

  List<TransferModel> _mock() => List.from(_mockTransfers);
}
