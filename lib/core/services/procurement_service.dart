import 'package:dio/dio.dart';
import '../../models/procurement_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-03: جلب بيانات الشراء/الفواتير/الضمان للأصل.
/// الملفات نفسها تنزل برابط مؤقت من الباك اند؛ الفلاتر لا يخزنها محليا.
class ProcurementService {
  ProcurementService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<ProcurementInfo> fetchForAsset(String assetId) async {
    try {
      final res = await _api.get(
        '${AppConstants.assetsEndpoint}/$assetId/procurement',
      );
      final data = res.data is Map ? res.data['data'] ?? res.data : {};
      return ProcurementInfo.fromJson(
          Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        return ProcurementInfo(
          assetId: assetId,
          supplier: 'Mock Supplier Co.',
          purchaseOrder: 'PO-2024-0117',
          invoiceId: 'INV-2024-0932',
          warrantyProvider: 'BrandX Care',
          warrantyExpiry: '2026-12-31',
          warrantyTerms: '2y on-site, battery 1y',
          attachments: const ['invoice_INV-2024-0932.pdf', 'warranty_card.pdf'],
        );
      }
      rethrow;
    }
  }
}
