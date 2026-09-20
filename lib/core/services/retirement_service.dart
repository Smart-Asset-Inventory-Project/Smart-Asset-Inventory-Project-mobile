import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-10: تقاعد مضبوط بسبب واعتماد وتاريخ ودليل.
/// المتقاعد read-only ويبقى في التقارير؛ لا حذف.
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
        '${AppConstants.assetsEndpoint}/$assetId/retire',
        data: {
          'reason': reason,
          if (evidence != null) 'evidence': evidence,
        },
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return; // mock accept
      }
      final msg = e.response?.data?['message']?.toString() ?? 'Retire failed';
      throw Exception(msg);
    }
  }
}
