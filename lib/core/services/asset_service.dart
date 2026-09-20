import 'package:dio/dio.dart';
import '../../models/asset_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-01/02: جلب وبحث الأصول.
/// يحاول الباك اند أولا، ويسقط لبيانات synthetic محلية لو السيرفر واقع.
class AssetService {
  AssetService({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<List<AssetModel>> fetchAssets({
    String? query,
    String? locationId,
    String? category,
  }) async {
    try {
      final res = await _api.get(
        AppConstants.assetsEndpoint,
        query: {
          if (query != null && query.isNotEmpty) 'q': query,
          if (locationId != null) 'locationId': locationId,
          if (category != null) 'category': category,
        },
      );
      final raw = res.data is List
          ? res.data as List
          : (res.data['data'] as List? ?? []);
      return raw
          .map((e) => AssetModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return _mockAssets(
            query: query, category: category, locationId: locationId);
      }
      rethrow;
    }
  }

  Future<AssetModel> fetchAssetDetail(String id) async {
    try {
      final res = await _api.get('${AppConstants.assetsEndpoint}/$id');
      final data = res.data is Map ? res.data['data'] ?? res.data : {};
      return AssetModel.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return _mockAssets().firstWhere((a) => a.id == id,
            orElse: () => _mockAssets().first);
      }
      rethrow;
    }
  }

  /// AST-FR-02: إنشاء أصل. يرمي رسالة واضحة لو Tag/Serial مكرر (409).
  Future<AssetModel> createAsset(Map<String, dynamic> payload) async {
    try {
      final res = await _api.post(AppConstants.assetsEndpoint, data: payload);
      final data = res.data is Map ? res.data['data'] ?? res.data : {};
      return AssetModel.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final msg =
            e.response?.data?['message']?.toString() ?? 'Duplicate tag/serial';
        throw Exception(msg);
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        // mock accept محلي حتى يجهز الباك اند
        return AssetModel.fromJson({
          'id': 'mock-${DateTime.now().millisecondsSinceEpoch}',
          'tag': payload['tag'],
          'serial': payload['serial'],
          'category': payload['category'],
          'brand': payload['brand'],
          'model': payload['model'],
          'locationId': payload['locationId'],
          'condition': payload['condition'] ?? 'good',
          'status': 'active',
          'purchaseCost': payload['purchaseCost'],
          'purchaseDate': payload['purchaseDate'],
        });
      }
      final msg = e.response?.data?['message']?.toString() ?? 'Create failed';
      throw Exception(msg);
    }
  }

  // Synthetic فقط - لا بيانات حقيقية. يغطي مبنيين وفئات متنوعة.
  List<AssetModel> _mockAssets(
      {String? query, String? category, String? locationId}) {
    const categories = ['computer', 'screen', 'furniture', 'printer', 'lab'];
    final list = List.generate(20, (i) {
      final b = i < 12 ? 'B1' : 'B2';
      final cat = categories[i % categories.length];
      return AssetModel(
        id: 'mock-$i',
        tag: 'AST-$b-${1000 + i}',
        serial: 'SN-${2000 + i}',
        category: cat,
        brand: 'BrandX',
        model: 'Model-${i % 4}',
        locationId: b == 'B1' ? 'loc-b1-r101' : 'loc-b2-r201',
        custodianId: 'user-${i % 5}',
        condition: i % 7 == 0 ? 'needs_repair' : 'good',
        status: i % 9 == 0 ? 'in_maintenance' : 'active',
        purchaseCost: 5000 + i * 250,
        purchaseDate: '2023-0${(i % 9) + 1}-15',
      );
    });
    var out = list;
    if (locationId != null && locationId.isNotEmpty) {
      // المبنى/الدور يطابق كل ما تحته في الهرم mock.
      final prefix = locationId == 'loc-b1' || locationId == 'campus-1'
          ? 'loc-b1'
          : locationId == 'loc-b2'
              ? 'loc-b2'
              : locationId;
      out = out.where((a) => a.locationId.startsWith(prefix)).toList();
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      out = out.where((a) => a.category == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      out = out
          .where((a) =>
              a.tag.toLowerCase().contains(q) ||
              (a.serial ?? '').toLowerCase().contains(q) ||
              a.category.contains(q))
          .toList();
    }
    return out;
  }
}
