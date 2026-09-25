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

  /// Exact contract statuses: OPEN, ASSIGNED, IN_PROGRESS, COMPLETED,
  /// CANCELLED. App 'closed' means COMPLETED (terminal, with costs).
  /// NOTE: 'inProgress'.toUpperCase() gives 'INPROGRESS' (no underscore)
  /// which the backend rejects — never send raw uppercased app statuses.
  static String? _apiStatus(String? status) {
    switch (status) {
      case 'open':
        return 'OPEN';
      case 'assigned':
        return 'ASSIGNED';
      case 'inProgress':
        return 'IN_PROGRESS';
      case 'closed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return null;
    }
  }

  Future<List<WorkOrderModel>> fetchWorkOrders({
    String? status,
    String? priority,
    String? assetId,
    String? assignedToUserId,
  }) async {
    try {
      final res = await _api.get(AppConstants.workOrdersEndpoint, query: {
        'limit': '${AppConstants.pageSize}',
        if (_apiStatus(status) != null) 'status': _apiStatus(status)!,
        if (priority != null && priority.isNotEmpty)
          'priority': priority.toUpperCase(),
        if (assetId != null && assetId.isNotEmpty) 'assetId': assetId,
        if (assignedToUserId != null && assignedToUserId.isNotEmpty)
          'assignedToUserId': assignedToUserId,
      });
      final body = Map<String, dynamic>.from(res.data as Map);
      // Tolerant parse: one malformed record must not kill the whole list.
      // Nested `assignedTo` may be an object, a scalar id, or absent.
      final rawItems = (body['data'] as List? ?? []);
      var list = <WorkOrderModel>[];
      for (final e in rawItems) {
        try {
          if (e is Map) {
            list.add(WorkOrderModel.fromJson(
                Map<String, dynamic>.from(e)));
          }
        } catch (_) {}
      }
      final dir = UserDirectory.instance;
      for (final raw in rawItems) {
        if (raw is Map) {
          dir.learnDynamic(
              Map<String, dynamic>.from(raw)['assignedTo']);
        }
      }
      // فلترة الحالة محليا لضمان السلوك (open/inProgress/closed/cancelled).
      if (status != null && status != 'all') {
        list = list.where((w) => w.status == status).toList();
      }
      return list;
    } on DioException catch (_) {
      if (AppConstants.allowMockFallback) {
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
      if (AppConstants.allowMockFallback) {
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

  /// PUT /work-orders/:id/complete. Docs: {laborCost, partsCost,
  /// downtimeHours, outcome, notes}. Numbers as JSON numbers.
  /// laborCost/outcome added; old callers (notes/parts/downtime) still work.
  Future<void> closeWorkOrder({
    required String id,
    required String notes,
    double? laborCost,
    double? partsCost,
    double? downtimeHours,
    String? outcome,
  }) async {
    try {
      await _api.put(
        '${AppConstants.workOrdersEndpoint}/$id/complete',
        data: {
          if (laborCost != null) 'laborCost': laborCost,
          if (partsCost != null) 'partsCost': partsCost,
          if (downtimeHours != null) 'downtimeHours': downtimeHours,
          'outcome': (outcome == null || outcome.isEmpty) ? notes : outcome,
          'notes': notes,
        },
      );
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback) {
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

  /// PUT /work-orders/{id} status step: OPEN -> ASSIGNED (needs
  /// assignedToUserId) -> IN_PROGRESS -> CANCELLED from any nonterminal.
  Future<WorkOrderModel> updateStatus(
    String id,
    String status, {
    String? assignedToUserId,
  }) async {
    final upper = status.toUpperCase();
    try {
      final res = await _api.put(
        '${AppConstants.workOrdersEndpoint}/$id',
        data: {
          'status': upper,
          if (assignedToUserId != null && assignedToUserId.isNotEmpty)
            'assignedToUserId': assignedToUserId,
        },
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      return WorkOrderModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback) {
        return WorkOrderModel(
          id: id,
          assetId: '',
          priority: 'medium',
          status: status.toLowerCase(),
          technicianId: assignedToUserId,
        );
      }
      throw Exception(AuthService.backendMessage(e, 'Update failed'));
    }
  }

  /// Overdue = nonterminal (open/assigned/inProgress) + dueDate < today.
  /// No server filter per docs — computed client-side from one fetch.
  Future<List<WorkOrderModel>> fetchOverdue() async {
    final all = await fetchWorkOrders();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all.where((w) {
      if (w.status != 'open' &&
          w.status != 'assigned' &&
          w.status != 'inProgress') {
        return false;
      }
      final d = DateTime.tryParse(w.scheduledDate ?? '');
      if (d == null) return false;
      return DateTime(d.year, d.month, d.day).isBefore(today);
    }).toList();
  }

  /// GET /work-orders/due — due scheduling list.
  Future<List<WorkOrderModel>> fetchDueWorkOrders() async {
    try {
      final res = await _api.get(AppConstants.workOrdersDueEndpoint,
          query: {'limit': '${AppConstants.pageSize}'});
      final body = Map<String, dynamic>.from(res.data as Map);
      final list = <WorkOrderModel>[];
      for (final e in (body['data'] as List? ?? [])) {
        try {
          if (e is Map) {
            list.add(WorkOrderModel.fromJson(
                Map<String, dynamic>.from(e)));
          }
        } catch (_) {}
      }
      return list;
    } on DioException catch (e) {
      if ((AppConstants.allowMockFallback) ||
          e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }
}
