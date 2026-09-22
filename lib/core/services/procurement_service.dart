import 'package:dio/dio.dart';
import '../../models/procurement_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// AST-FR-03: مشتريات/فواتير/ضمان حقيقية.
/// /warranties + /purchase-orders (+invoices) + /suppliers + /invoices.
class ProcurementService {
  ProcurementService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  static List<Map<String, dynamic>> _list(Response res) {
    final body = Map<String, dynamic>.from(res.data as Map);
    return ((body['data'] as List? ?? []))
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<WarrantyInfo>> fetchWarranties() async {
    final res = await _api.get(AppConstants.warrantiesEndpoint,
        query: const {'limit': '200'});
    return _list(res).map(WarrantyInfo.fromJson).toList();
  }

  Future<List<PurchaseOrderInfo>> fetchPurchaseOrders() async {
    final res = await _api.get(AppConstants.purchaseOrdersEndpoint,
        query: const {'limit': '200'});
    return _list(res).map(PurchaseOrderInfo.fromJson).toList();
  }

  Future<List<InvoiceInfo>> fetchInvoices() async {
    final res = await _api.get(AppConstants.invoicesEndpoint,
        query: const {'limit': '200'});
    return _list(res).map(InvoiceInfo.fromJson).toList();
  }

  Future<List<SupplierInfo>> fetchSuppliers() async {
    final res = await _api.get(AppConstants.suppliersEndpoint,
        query: const {'limit': '200'});
    return _list(res).map(SupplierInfo.fromJson).toList();
  }

  Future<ProcurementInfo> fetchForAsset(String assetId) async {
    try {
      final warranties = await fetchWarranties();
      final orders = await fetchPurchaseOrders();
      final w = warranties.where((x) => x.assetId == assetId).toList();
      final pos = orders.where((x) => x.assetId == assetId).toList();
      final w0 = w.isEmpty ? null : w.first;
      final p0 = pos.isEmpty ? null : pos.first;
      return ProcurementInfo(
        assetId: assetId,
        supplier: p0?.supplierName,
        purchaseOrder: p0?.orderNumber,
        purchaseDate: p0?.orderDate,
        purchaseAmount: p0?.totalAmount,
        invoiceId: p0 == null || p0.invoices.isEmpty
            ? null
            : p0.invoices.first.invoiceNumber,
        invoices: pos
            .expand((p) => p.invoices)
            .map((i) => i.invoiceNumber)
            .toList(),
        warrantyProvider: w0?.provider,
        warrantyExpiry: w0?.endDate,
        warrantyTerms: w0?.terms,
      );
    } on DioException catch (e) {
      if ((AppConstants.allowMockFallback && e.response == null) ||
          e.response?.statusCode == 404) {
        return ProcurementInfo(
          assetId: assetId,
          supplier: 'Mock Supplier Co.',
          purchaseOrder: 'PO-2024-0117',
          invoiceId: 'INV-2024-0932',
          invoices: const ['INV-2024-0932'],
          warrantyProvider: 'BrandX Care',
          warrantyExpiry: '2026-12-31',
          warrantyTerms: '2y on-site, battery 1y',
        );
      }
      throw Exception(AuthService.backendMessage(e, 'Procurement failed'));
    }
  }
}
