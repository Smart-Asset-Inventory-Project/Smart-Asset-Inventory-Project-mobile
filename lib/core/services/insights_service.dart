import 'package:dio/dio.dart';
import '../../models/work_order_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-07/08/09: الجرد والمخاطر للعرض في الفلاتر.
/// الباك اند هو مصدر الحقيقة؛ هنا fallback synthetic للعمل بدون سيرفر.
class InsightsService {
  InsightsService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<RiskItemModel>> fetchRiskQueue() async {
    try {
      final res = await _api.get(AppConstants.riskQueueEndpoint);
      final raw = res.data is List
          ? res.data as List
          : (res.data['data'] as List? ?? []);
      return raw
          .map((e) =>
              RiskItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return const [
          RiskItemModel(
            assetId: 'mock-6',
            assetTag: 'AST-B1-1006',
            band: 'high',
            reasons: ['overdue 12 days', '3 failures in 90d'],
            score: 0.91,
          ),
          RiskItemModel(
            assetId: 'mock-7',
            assetTag: 'AST-B2-1015',
            band: 'medium',
            reasons: ['warranty expires in 20d', 'age 4.5/5y'],
            score: 0.62,
          ),
          RiskItemModel(
            assetId: 'mock-8',
            assetTag: 'AST-B1-1008',
            band: 'low',
            reasons: ['due in 25d'],
            score: 0.31,
          ),
        ];
      }
      rethrow;
    }
  }
}
