import 'package:dio/dio.dart';
import '../../models/retirement_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// AST-FR-10: تقاعد حقيقي.
/// POST /retirements {assetId, reason} + GET /retirements للقوائم.
class RetirementService {
  RetirementService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<void> retire({
    required String assetId,
    required String reason,
    String? evidence,
  }) async {
    try {
      await _api.post(
        AppConstants.retirementsEndpoint,
        data: {
          'assetId': assetId,
          'reason': reason,
          if (evidence != null && evidence.isNotEmpty) 'evidence': evidence,
        },
      );
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback) {
        return; // mock accept
      }
      throw Exception(AuthService.backendMessage(e, 'Retire failed'));
    }
  }

  Future<List<RetirementInfo>> fetchRetirements() async {
    try {
      final res = await _api.get(AppConstants.retirementsEndpoint,
          query: {'limit': '${AppConstants.pageSize}'});
      final body = Map<String, dynamic>.from(res.data as Map);
      return ((body['data'] as List? ?? []))
          .map((e) => RetirementInfo.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if ((AppConstants.allowMockFallback) ||
          e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }
}
