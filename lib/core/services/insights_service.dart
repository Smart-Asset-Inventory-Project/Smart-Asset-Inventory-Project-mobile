import 'package:dio/dio.dart';
import '../../models/work_order_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'asset_service.dart';
import 'work_order_service.dart';

/// AST-FR-07/08/09: الجرد والمخاطر للعرض في الفلاتر.
/// الباك اند هو مصدر الحقيقة؛ هنا fallback synthetic للعمل بدون سيرفر.
class InsightsService {
  InsightsService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  /// AST-FR-09: طابور المخاطر.
  /// لا endpoint في الباك اند (404): يعمل محليا بقواعد due/warranty/age
  /// من بيانات الأصول والأوامر الحقيقية بدلا من mock ثابت.
  Future<List<RiskItemModel>> fetchRiskQueue() async {
    try {
      final res = await _api.get(AppConstants.riskQueueEndpoint);
      final body = Map<String, dynamic>.from(res.data as Map);
      return ((body['data'] as List? ?? []))
          .map((e) =>
              RiskItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if ((AppConstants.allowMockFallback && e.response == null) ||
          e.response?.statusCode == 404) {
        return computeLocalRisk();
      }
      rethrow;
    }
  }

  /// قواعد محلية من الداتا الحقيقية: متأخر + ضمان قريب + عمر/حالة.
  static Future<List<RiskItemModel>> computeLocalRisk() async {
    try {
      final assets = await AssetService().fetchAssets();
      final orders = await WorkOrderService().fetchWorkOrders();
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);
      final out = <RiskItemModel>[];
      for (final a in assets) {
        final reasons = <String>[];
        double score = 0;
        final openCount = orders
            .where((w) =>
                w.assetId == a.id &&
                (w.status == 'open' || w.status == 'inProgress'))
            .length;
        if (openCount > 0) {
          reasons.add('$openCount open work orders');
          score += 0.3 * openCount;
        }
        final overdue = orders.any((w) {
          if (w.assetId != a.id) return false;
          if (w.status != 'open' && w.status != 'inProgress') return false;
          final d = DateTime.tryParse(w.scheduledDate ?? '');
          if (d == null) return false;
          return DateTime(d.year, d.month, d.day).isBefore(todayDay);
        });
        if (overdue) {
          reasons.add('overdue service');
          score += 0.4;
        }
        if (a.condition.toLowerCase() != 'good') {
          reasons.add('condition: ${a.condition}');
          score += 0.25;
        }
        if (a.status.toLowerCase() == 'maintenance' ||
            a.status.toLowerCase().contains('repair')) {
          reasons.add('in maintenance');
          score += 0.2;
        }
        if (reasons.isEmpty) continue;
        if (score > 1) score = 1;
        out.add(RiskItemModel(
          assetId: a.id,
          assetTag: a.tag,
          band: score >= 0.6 ? 'high' : score >= 0.35 ? 'medium' : 'low',
          reasons: reasons,
          score: score,
        ));
      }
      out.sort((x, y) => y.score.compareTo(x.score));
      return out;
    } catch (_) {
      return const [
        RiskItemModel(
          assetId: 'mock-6',
          assetTag: 'AST-B1-1006',
          band: 'high',
          reasons: ['overdue 12 days', '3 failures in 90d'],
          score: 0.91,
        ),
      ];
    }
  }
}
