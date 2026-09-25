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

  Future<List<WarrantyInfo>> fetchWarranties({String? assetId}) async {
    final res = await _api.get(AppConstants.warrantiesEndpoint, query: {
      'limit': '${AppConstants.pageSize}',
      if (assetId != null && assetId.isNotEmpty) 'assetId': assetId,
    });
    return _list(res).map(WarrantyInfo.fromJson).toList();
  }

  /// GET /warranties/expiring?days=30 — future expirations within days.
  Future<List<WarrantyInfo>> fetchExpiringWarranties({int days = 30}) async {
    try {
      final res = await _api.get(
        AppConstants.warrantiesExpiringEndpoint,
        query: {'limit': '${AppConstants.pageSize}', 'days': '$days'},
      );
      return _list(res).map(WarrantyInfo.fromJson).toList();
    } on DioException catch (e) {
      if ((AppConstants.allowMockFallback) ||
          e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  Future<List<PurchaseOrderInfo>> fetchPurchaseOrders({String? status}) async {
    final res = await _api.get(AppConstants.purchaseOrdersEndpoint, query: {
      'limit': '${AppConstants.pageSize}',
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return _list(res).map(PurchaseOrderInfo.fromJson).toList();
  }

  Future<List<InvoiceInfo>> fetchInvoices({String? status}) async {
    final res = await _api.get(AppConstants.invoicesEndpoint, query: {
      'limit': '${AppConstants.pageSize}',
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return _list(res).map(InvoiceInfo.fromJson).toList();
  }

  Future<List<SupplierInfo>> fetchSuppliers({String? search}) async {
    final res = await _api.get(AppConstants.suppliersEndpoint, query: {
      'limit': '${AppConstants.pageSize}',
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return _list(res).map(SupplierInfo.fromJson).toList();
  }

  /// Supplier -> PO -> invoice workflow. Money as JSON numbers.
  /// Invoiced POs cannot switch suppliers or be deleted (409).
  Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> data) async {
    final res = await _api.post(AppConstants.suppliersEndpoint, data: data);
    return Map<String, dynamic>.from(
        (Map<String, dynamic>.from(res.data as Map))['data'] as Map);
  }

  Future<Map<String, dynamic>> createPurchaseOrder(Map<String, dynamic> data) async {
    final res = await _api.post(AppConstants.purchaseOrdersEndpoint, data: data);
    return Map<String, dynamic>.from(
        (Map<String, dynamic>.from(res.data as Map))['data'] as Map);
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final res = await _api.post(AppConstants.invoicesEndpoint, data: data);
    return Map<String, dynamic>.from(
        (Map<String, dynamic>.from(res.data as Map))['data'] as Map);
  }

  Future<Map<String, dynamic>> createWarranty(Map<String, dynamic> data) async {
    final res = await _api.post(AppConstants.warrantiesEndpoint, data: data);
    return Map<String, dynamic>.from(
        (Map<String, dynamic>.from(res.data as Map))['data'] as Map);
  }

  Future<void> deleteSupplier(String id) async {
    await _api.delete('${AppConstants.suppliersEndpoint}/$id');
  }

  Future<void> deletePurchaseOrder(String id) async {
    await _api.delete('${AppConstants.purchaseOrdersEndpoint}/$id');
  }

  Future<ProcurementInfo> fetchForAsset(String assetId) async {
    try {
      // Server-side filter first — was downloading all warranties + orders.
      final results = await Future.wait([
        fetchWarranties(assetId: assetId),
        fetchPurchaseOrders(),
      ]);
      final warranties = results[0] as List<WarrantyInfo>;
      final allOrders = results[1] as List<PurchaseOrderInfo>;
      final orders = allOrders.where((x) {
        if (x.assetId.isNotEmpty) return x.assetId == assetId;
        return true;
      }).toList();
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
      if ((AppConstants.allowMockFallback) ||
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
