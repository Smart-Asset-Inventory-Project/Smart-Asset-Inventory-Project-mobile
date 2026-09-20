import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-03: تنزيل المرفقات برابط مؤقت.
/// لا يعرض محتوى مالي لمستخدم غير مصرح له؛ الباك اند هو من يمنع.
class DocumentService {
  DocumentService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  /// يرجع رابط التنزيل المؤقت. يعرض رسالة الباك اند لو 403.
  Future<String> downloadUrl(String filename) async {
    try {
      final res = await _api.get('/documents/url',
          query: {'file': filename});
      final data = res.data is Map ? res.data['data'] ?? res.data : {};
      return (data['url'] ?? '').toString();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Access denied: procurement permission required');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return '${AppConstants.baseUrl}/mock-docs/$filename';
      }
      rethrow;
    }
  }
}
