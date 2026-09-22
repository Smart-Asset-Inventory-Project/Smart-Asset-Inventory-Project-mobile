import 'package:dio/dio.dart';
import '../../models/work_order_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'user_directory.dart';

/// AST-FR-05/06: جلب وإنشاء الأوامر + إغلاق يحدث history الأصل في الباك اند.
class WorkOrderService {
  WorkOrderService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  static final List<WorkOrderModel> _mockOrders = [
    const WorkOrderModel(
      id: 'wo1',
      assetId: 'AST-B1-1001',
      priority: 'high',
      status: 'open',
      technicianId: 'tech-1',
      scheduledDate: '2026-09-21',
      notes: 'Periodic computer maintenance',
    ),
    const WorkOrderModel(
      id: 'wo2',
      assetId: 'AST-B1-1003',
      priority: 'medium',
      status: 'inProgress',
      technicianId: 'tech-2',
      scheduledDate: '2026-09-20',
    ),
    const WorkOrderModel(
      id: 'wo3',
      assetId: 'AST-B2-1005',
      priority: 'low',
      status: 'closed',
      technicianId: 'tech-1',
      scheduledDate: '2026-09-10',
      notes: 'Replaced fan, tested OK',
    ),
  ];

  Future<List<WorkOrderModel>> fetchWorkOrders({String? status}) async {
    try {
      final res = await _api.get(AppConstants.workOrdersEndpoint,
          query: const {'limit': '200'});
      final body = Map<String, dynamic>.from(res.data as Map);
      var list = ((body['data'] as List? ?? []))
          .map((e) =>
              WorkOrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final dir = UserDirectory.instance;
      for (final raw in (body['data'] as List? ?? [])) {
        dir.learnMap(
            (Map<String, dynamic>.from(raw as Map))['assignedTo'] as Map?);
      }
      // فلترة الحالة محليا لضمان السلوك (open/inProgress/closed/cancelled).
      if (status != null && status != 'all') {
        list = list.where((w) => w.status == status).toList();
      }
      return list;
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        return _mock(status);
      }
      rethrow;
    }
  }

  Future<WorkOrderModel> createWorkOrder(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(AppConstants.workOrdersEndpoint, data: data);
      final body = Map<String, dynamic>.from(res.data as Map);
      final item = WorkOrderModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
      _mockOrders.insert(0, item);
      return item;
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        final item = WorkOrderModel(
          id: 'wo${DateTime.now().millisecondsSinceEpoch % 10000}',
          assetId: (data['assetId'] ?? 'AST-B1-1001').toString(),
          priority: (data['priority'] ?? 'medium').toString(),
          status: 'open',
          technicianId: data['assignedToUserId']?.toString(),
          scheduledDate: data['dueDate']?.toString() ??
              DateTime.now().toIso8601String().substring(0, 10),
          notes: data['description']?.toString(),
          title: data['title']?.toString(),
        );
        _mockOrders.insert(0, item);
        return item;
      }
      throw Exception(AuthService.backendMessage(e, 'Create failed'));
    }
  }

  /// PUT /work-orders/:id/complete. الباك اند يحدث history الأصل.
  Future<void> closeWorkOrder({
    required String id,
    required String notes,
    double? partsCost,
    double? downtimeHours,
  }) async {
    try {
      await _api.put(
        '${AppConstants.workOrdersEndpoint}/$id/complete',
        data: {
          'notes': notes,
          if (partsCost != null) 'partsCost': partsCost,
          if (downtimeHours != null) 'downtimeHours': downtimeHours,
        },
      );
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        final idx = _mockOrders.indexWhere((w) => w.id == id);
        if (idx != -1) {
          final old = _mockOrders[idx];
          _mockOrders[idx] = WorkOrderModel(
            id: old.id,
            assetId: old.assetId,
            priority: old.priority,
            status: 'closed',
            technicianId: old.technicianId,
            scheduledDate: old.scheduledDate,
            notes: notes,
          );
        }
        return; // mock accept
      }
      throw Exception(AuthService.backendMessage(e, 'Close failed'));
    }
  }

  List<WorkOrderModel> _mock(String? status) {
    if (status == null || status == 'all') return List.from(_mockOrders);
    return _mockOrders.where((w) => w.status == status).toList();
  }
}
