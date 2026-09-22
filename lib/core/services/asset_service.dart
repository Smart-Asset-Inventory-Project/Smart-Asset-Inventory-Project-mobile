import 'package:dio/dio.dart';
import '../../models/asset_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'location_service.dart';

/// AST-FR-01/02: جلب وبحث الأصول.
/// يحاول الباك اند أولا، ويسقط لبيانات synthetic محلية لو السيرفر واقع.
class AssetService {
  AssetService({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<List<AssetModel>> fetchAssets({
    String? query,
    String? locationId,
    String? category,
    String? scopeLocationId,
  }) async {
    try {
      // limit كبير لأن الباك اند يصفح (20 افتراضيا).
      // الفلترة client-side لضمان السلوك مهما دعم السيرفر.
      final res = await _api.get(
        AppConstants.assetsEndpoint,
        query: const {'limit': '200'},
      );
      final body = res.data as Map;
      final raw = (body['data'] as List? ?? []);
      var list = raw
          .map((e) => AssetModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (locationId != null && locationId.isNotEmpty) {
        list = list.where((a) => a.locationId == locationId).toList();
      }
      // Scope-Based: نطاق الكاستوديان = الموقع + كل ما تحته.
      if (scopeLocationId != null && scopeLocationId.isNotEmpty) {
        try {
          final locs = await LocationService(api: _api).fetchLocations();
          final scope =
              LocationService.subtreeIds(locs, scopeLocationId);
          list = list.where((a) => scope.contains(a.locationId)).toList();
        } catch (_) {
          // لو المواقع فشلت يعرض الكل بدلا من شاشة فاضية
        }
      }
      if (category != null && category.isNotEmpty) {
        final c = category.toLowerCase();
        list = list
            .where((a) =>
                a.category.toLowerCase() == c ||
                a.categoryId == category)
            .toList();
      }
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        list = list
            .where((a) =>
                a.tag.toLowerCase().contains(q) ||
                (a.serial ?? '').toLowerCase().contains(q) ||
                (a.name ?? '').toLowerCase().contains(q) ||
                a.category.toLowerCase().contains(q))
            .toList();
      }
      return list;
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
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
      if (AppConstants.allowMockFallback && e.response == null) {
        return _mockAssets().firstWhere((a) => a.id == id,
            orElse: () => _mockAssets().first);
      }
      rethrow;
    }
  }

  /// PUT /assets/:id لتعديل أصل. رسالة الخطأ من السيرفر.
  Future<AssetModel> updateAsset(String id, Map<String, dynamic> payload) async {
    try {
      final res = await _api.put('${AppConstants.assetsEndpoint}/$id',
          data: payload);
      final body = Map<String, dynamic>.from(res.data as Map);
      return AssetModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        return AssetModel.fromJson({
          'id': id,
          'assetTag': payload['assetTag'],
          'serialNumber': payload['serialNumber'],
          'category': {'name': ''},
          'model': payload['model'],
          'locationId': payload['locationId'],
          'condition': payload['condition'] ?? 'good',
          'status': payload['status'] ?? 'active',
          'purchaseCost': payload['purchaseCost'],
        });
      }
      throw Exception(AuthService.backendMessage(e, 'Update failed'));
    }
  }

  /// DELETE /assets/:id لحذف أصل.
  Future<void> deleteAsset(String id) async {
    try {
      await _api.dio.delete('${AppConstants.assetsEndpoint}/$id');
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) return;
      throw Exception(AuthService.backendMessage(e, 'Delete failed'));
    }
  }
  /// assetTag, name, categoryId, locationId. رسالة الخطأ من السيرفر.
  /// AST-FR-02: إنشاء أصل. الحقول المطلوبة في الباك اند:
  /// assetTag, name, categoryId, locationId. رسالة الخطأ من السيرفر.
  Future<AssetModel> createAsset(Map<String, dynamic> payload) async {
    try {
      final res = await _api.post(AppConstants.assetsEndpoint, data: payload);
      final body = Map<String, dynamic>.from(res.data as Map);
      return AssetModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        // mock accept محلي للاختبارات فقط
        return AssetModel.fromJson({
          'id': 'mock-${DateTime.now().millisecondsSinceEpoch}',
          'assetTag': payload['assetTag'] ?? payload['tag'],
          'serialNumber': payload['serialNumber'] ?? payload['serial'],
          'category': {'name': payload['category'] ?? ''},
          'model': payload['model'],
          'locationId': payload['locationId'],
          'condition': payload['condition'] ?? 'good',
          'status': 'active',
          'purchaseCost': payload['purchaseCost'],
          'purchaseDate': payload['purchaseDate'],
        });
      }
      throw Exception(
          AuthService.backendMessage(e, 'Create failed'));
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
