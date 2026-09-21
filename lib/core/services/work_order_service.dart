import 'package:dio/dio.dart';
import '../../models/work_order_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-05/06: جلب الأوامر + إغلاق يحدث history الأصل في الباك اند.
class WorkOrderService {
  WorkOrderService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<WorkOrderModel>> fetchWorkOrders({String? status}) async {
    try {
      final res = await _api.get(AppConstants.workOrdersEndpoint,
          query: {if (status != null) 'status': status});
      final raw = res.data is List
          ? res.data as List
          : (res.data['data'] as List? ?? []);
      return raw
          .map((e) =>
              WorkOrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        return _mock(status);
      }
      rethrow;
    }
  }

  Future<void> closeWorkOrder({
    required String id,
    required String notes,
    double? partsCost,
    double? downtimeHours,
  }) async {
    try {
      await _api.patch(
        '${AppConstants.workOrdersEndpoint}/$id/close',
        data: {
          'notes': notes,
          if (partsCost != null) 'partsCost': partsCost,
          if (downtimeHours != null) 'downtimeHours': downtimeHours,
          'status': 'closed',
        },
      );
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        return; // mock accept
      }
      rethrow;
    }
  }

  List<WorkOrderModel> _mock(String? status) {
    final all = [
      const WorkOrderModel(
        id: 'wo1',
        assetId: 'mock-1',
        priority: 'high',
        status: 'open',
        technicianId: 'tech-1',
        scheduledDate: '2026-09-21',
        notes: 'Periodic computer maintenance',
      ),
      const WorkOrderModel(
        id: 'wo2',
        assetId: 'mock-3',
        priority: 'medium',
        status: 'inProgress',
        technicianId: 'tech-2',
        scheduledDate: '2026-09-20',
      ),
      const WorkOrderModel(
        id: 'wo3',
        assetId: 'mock-5',
        priority: 'low',
        status: 'closed',
        technicianId: 'tech-1',
        scheduledDate: '2026-09-10',
        notes: 'Replaced fan, tested OK',
      ),
    ];
    if (status == null || status == 'all') return all;
    return all.where((w) => w.status == status).toList();
  }
}
