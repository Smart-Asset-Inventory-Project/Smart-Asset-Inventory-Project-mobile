import 'package:dio/dio.dart';
import '../../models/category_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'user_directory.dart';

/// قوائم الكتالوج للفورمات: الفئات والموردون.
class CatalogService {
  CatalogService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  /// 5-min memory cache: categories rarely change, fetched on every
  /// asset list/form open.
  static List<CategoryModel>? _catCache;
  static DateTime? _catAt;
  static const _ttl = Duration(minutes: 5);

  Future<List<CategoryModel>> fetchCategories() async {
    if (_catCache != null &&
        _catAt != null &&
        DateTime.now().difference(_catAt!) < _ttl) {
      return _catCache!;
    }
    final res = await _api.get(AppConstants.categoriesEndpoint,
        query: {'limit': '${AppConstants.pageSize}'});
    final body = Map<String, dynamic>.from(res.data as Map);
    final list = ((body['data'] as List? ?? []))
        .map((e) =>
            CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _catCache = list;
    _catAt = DateTime.now();
    return list;
  }
}

/// سجل تدقيق واحد من /audit-logs.
class AuditLogInfo {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String? userId;
  final String? userName;
  final String createdAt;

  const AuditLogInfo({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.userId,
    this.userName,
    required this.createdAt,
  });

  factory AuditLogInfo.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return AuditLogInfo(
      id: json['id'].toString(),
      entityType: (json['entityType'] ?? '').toString(),
      entityId: (json['entityId'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      userId: (json['userId'] ?? (user is Map ? user['id'] : null))
          ?.toString(),
      userName: user is Map ? user['name']?.toString() : null,
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class AuditService {
  AuditService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<AuditLogInfo>> fetchLogs({int limit = 50}) async {
    final res = await _api.get(AppConstants.auditLogsEndpoint,
        query: {'limit': '$limit'});
    final body = Map<String, dynamic>.from(res.data as Map);
    final items = ((body['data'] as List? ?? []))
        .map((e) =>
            AuditLogInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final dir = UserDirectory.instance;
    for (final l in items) {
      dir.learn(l.userId, l.userName);
    }
    return items;
  }
}

/// ملخص /dashboard/summary للادمن.
class DashboardSummary {
  final int totalAssets;
  final int activeAssets;
  final int maintenanceAssets;
  final int retiredAssets;
  final int openWorkOrders;
  final int overdueWorkOrders;
  final int dueSoonWorkOrders;
  final int expiringWarranties30d;
  final double totalValue;

  const DashboardSummary({
    required this.totalAssets,
    required this.activeAssets,
    required this.maintenanceAssets,
    required this.retiredAssets,
    required this.openWorkOrders,
    required this.overdueWorkOrders,
    required this.dueSoonWorkOrders,
    required this.expiringWarranties30d,
    required this.totalValue,
  });

  static int _i(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalAssets: _i(json['totalAssets']),
        activeAssets: _i(json['activeAssets']),
        maintenanceAssets: _i(json['maintenanceAssets']),
        retiredAssets: _i(json['retiredAssets']),
        openWorkOrders: _i(json['openWorkOrders']),
        overdueWorkOrders: _i(json['overdueWorkOrders']),
        dueSoonWorkOrders: _i(json['dueSoonWorkOrders']),
        expiringWarranties30d: _i(json['expiringWarranties30d']),
        totalValue: _d(json['totalValue']),
      );
}

class DashboardApi {
  DashboardApi({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<DashboardSummary?> fetchSummary() async {
    try {
      final res = await _api.get(AppConstants.dashboardSummaryEndpoint);
      final body = Map<String, dynamic>.from(res.data as Map);
      return DashboardSummary.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
    } on DioException catch (e) {
      if ((AppConstants.allowMockFallback) ||
          e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}
