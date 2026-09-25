import 'package:dio/dio.dart';
import '../../models/service_event_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// GET /service-events?workOrderId=… + POST /service-events.
/// Costs as JSON numbers; cost must equal labor + parts.
/// Cancelled work orders reject service (409).
class ServiceEventService {
  ServiceEventService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<ServiceEvent>> fetchForWorkOrder(String workOrderId) async {
    try {
      final res = await _api.get(
        AppConstants.serviceEventsEndpoint,
        query: {
          'limit': '${AppConstants.pageSize}',
          'workOrderId': workOrderId,
        },
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      return ((body['data'] as List? ?? []))
          .map((e) =>
              ServiceEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (_) {
      if (AppConstants.allowMockFallback) return [];
      rethrow;
    }
  }

  Future<ServiceEvent> add({
    required String workOrderId,
    double? laborCost,
    double? partsCost,
    double? downtimeHours,
    String? outcome,
    String? notes,
  }) async {
    try {
      final res = await _api.post(
        AppConstants.serviceEventsEndpoint,
        data: {
          'workOrderId': workOrderId,
          if (laborCost != null) 'laborCost': laborCost,
          if (partsCost != null) 'partsCost': partsCost,
          if (downtimeHours != null) 'downtimeHours': downtimeHours,
          if (outcome != null && outcome.isNotEmpty) 'outcome': outcome,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      return ServiceEvent.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback) {
        return ServiceEvent(
          id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
          workOrderId: workOrderId,
          laborCost: laborCost?.toString(),
          partsCost: partsCost?.toString(),
          downtimeHours: downtimeHours,
          outcome: outcome ?? 'completed',
          notes: notes,
        );
      }
      throw Exception(AuthService.backendMessage(e, 'Service failed'));
    }
  }
}
