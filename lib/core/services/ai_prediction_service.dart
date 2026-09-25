import 'package:dio/dio.dart';
import '../../models/ai_prediction_model.dart';
import '../../models/asset_model.dart';
import 'service_event_service.dart';
import 'work_order_service.dart';

/// Predictive-maintenance AI (Railway) — separate Dio, NO auth header.
/// Never send the AssetHub bearer token to this third party.
class AiPredictionService {
  AiPredictionService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://smart-asset-ai-production.up.railway.app',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;
  final WorkOrderService _orders = WorkOrderService();
  final ServiceEventService _events = ServiceEventService();

  static const _window = Duration(days: 90);

  /// Assembles the 8 required fields from REAL asset data.
  /// Throws [AiRequestException] when a required input cannot be derived
  /// (missing purchaseDate / usefulLifeYears / condition) — the request
  /// is never sent with silent zeros for age or lifetime.
  Future<AiPredictRequest> buildRequest(AssetModel asset) async {
    final age = asset.ageMonths;
    if (age == null) {
      throw const AiRequestException(
          'Cannot predict: asset has no purchase date (age unknown).');
    }
    final life = asset.expectedLifetimeMonths;
    if (life == null || life <= 0) {
      throw const AiRequestException(
          'Cannot predict: asset has no useful life (lifetime unknown).');
    }
    final condition = AiPredictRequest.mapCondition(asset.condition);
    if (condition.isEmpty) {
      throw const AiRequestException(
          'Cannot predict: asset has no condition value.');
    }
    final orders = await _orders.fetchWorkOrders(assetId: asset.id);
    final now = DateTime.now();
    bool inWindow(String? iso) {
      final d = DateTime.tryParse(iso ?? '');
      if (d == null) return false;
      return !d.isAfter(now) && now.difference(d) <= _window;
    }

    final recentClosed = orders
        .where((w) =>
            w.status == 'closed' &&
            inWindow(w.completedAt ?? w.scheduledDate))
        .toList();
    double downtime = 0;
    double repair = 0;
    var hasCostRecords = false;
    if (recentClosed.isNotEmpty) {
      final lists = await Future.wait(
        recentClosed.map((w) => _events
            .fetchForWorkOrder(w.id)
            .then((v) => v, onError: (_) => [])),
      );
      for (final evs in lists) {
        for (final e in evs) {
          hasCostRecords = true;
          downtime += e.downtimeHours ?? 0;
          final labor = double.tryParse(e.laborCost ?? '') ?? 0;
          final parts = double.tryParse(e.partsCost ?? '') ?? 0;
          var total = labor + parts;
          if (total == 0) {
            total = double.tryParse(e.cost ?? '') ?? 0;
          }
          repair += total;
        }
      }
    }
    lastHadCostRecords = hasCostRecords;
    return AiPredictRequest(
      assetId: asset.id,
      assetAgeMonths: age,
      expectedLifetimeMonths: life,
      condition: condition,
      maintenanceCount: orders.length,
      recentMaintenanceCount90d: recentClosed.length,
      downtimeHours90d: downtime,
      repairCost90d: repair,
    );
  }

  /// Result of [buildRequest] cost-record coverage (parallel out value).
  /// True when at least one service event backed the 90d sums.
  bool lastHadCostRecords = false;

  Future<AiPredictResult> predict(AiPredictRequest req) async {
    try {
      final res = await _dio.post('/api/v1/predict', data: req.toJson());
      return AiPredictResult.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final details = <String>[];
        final data = e.response?.data;
        final arr = data is Map ? data['detail'] : null;
        if (arr is List) {
          for (final d in arr) {
            if (d is Map) {
              final loc = (d['loc'] as List?)?.join('.') ?? '';
              final msg = (d['msg'] ?? '').toString();
              details.add(loc.isEmpty ? msg : '$loc: $msg');
            }
          }
        }
        throw AiRequestException(
            'AI rejected the data (422)', details.isEmpty ? const ['Invalid request data'] : details);
      }
      final code = e.response?.statusCode;
      if (code == null) {
        throw const AiRequestException(
            'Cannot reach the AI service — check internet and retry.');
      }
      throw AiRequestException('AI service error ($code) — retry later.');
    }
  }

  /// One call used by the UI: request (+coverage flag) then prediction.
  Future<({AiPredictRequest req, AiPredictResult res, bool costRecords})>
      predictForAsset(AssetModel asset) async {
    final req = await buildRequest(asset);
    final res = await predict(req);
    return (req: req, res: res, costRecords: lastHadCostRecords);
  }
}
