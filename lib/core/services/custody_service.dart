import 'package:dio/dio.dart';
import '../../models/custody_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// POST /custody-assignments {assetId, userId, notes?}.
/// Release: PUT /{id} {returnedAt, notes?}. Duplicate active -> 409.
/// Historical assignments cannot be deleted.
class CustodyService {
  CustodyService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<CustodyAssignment>> fetchAssignments({
    String? assetId,
    bool? active,
  }) async {
    try {
      final res = await _api.get(
        AppConstants.custodyAssignmentsEndpoint,
        query: {
          'limit': '${AppConstants.pageSize}',
          if (assetId != null && assetId.isNotEmpty) 'assetId': assetId,
          if (active != null) 'active': '$active',
        },
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      return ((body['data'] as List? ?? []))
          .map((e) => CustodyAssignment.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (_) {
      if (AppConstants.allowMockFallback) return [];
      rethrow;
    }
  }

  Future<CustodyAssignment> assign({
    required String assetId,
    required String userId,
    String? notes,
  }) async {
    try {
      final res = await _api.post(
        AppConstants.custodyAssignmentsEndpoint,
        data: {
          'assetId': assetId,
          'userId': userId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      return CustodyAssignment.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback) {
        return CustodyAssignment(
          id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
          assetId: assetId,
          userId: userId,
          assignedAt: DateTime.now().toIso8601String(),
          notes: notes,
        );
      }
      throw Exception(AuthService.backendMessage(e, 'Assign failed'));
    }
  }

  Future<CustodyAssignment> release({
    required String id,
    String? notes,
  }) async {
    try {
      final res = await _api.put(
        '${AppConstants.custodyAssignmentsEndpoint}/$id',
        data: {
          'returnedAt': DateTime.now().toIso8601String(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      return CustodyAssignment.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback) {
        return CustodyAssignment(
          id: id,
          assetId: '',
          userId: '',
          returnedAt: DateTime.now().toIso8601String(),
          notes: notes,
        );
      }
      throw Exception(AuthService.backendMessage(e, 'Release failed'));
    }
  }
}
