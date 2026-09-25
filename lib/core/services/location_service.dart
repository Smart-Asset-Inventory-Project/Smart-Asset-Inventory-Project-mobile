import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/asset_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-01: هرم Locations.
/// campus > building > college > floor > room > office.
class LocationService {
  LocationService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  /// 2-min memory cache: locations are near-static and fetched by
  /// dashboard, transfers, asset forms on every open.
  static List<LocationModel>? _cache;
  static DateTime? _cacheAt;
  static const _ttl = Duration(minutes: 2);

  static void clearCache() {
    _cache = null;
    _cacheAt = null;
  }

  Future<List<LocationModel>> fetchLocations({String? search, String? parentId}) async {
    final filtered = (search != null && search.isNotEmpty) ||
        (parentId != null && parentId.isNotEmpty);
    if (!filtered &&
        _cache != null &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _ttl) {
      return _cache!;
    }
    try {
      final res = await _api.get(AppConstants.locationsEndpoint, query: {
        'limit': '${AppConstants.pageSize}',
        if (search != null && search.isNotEmpty) 'search': search,
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
      });
      final body = Map<String, dynamic>.from(res.data as Map);
      final raw = _extractList(body['data']);
      if (kDebugMode) {
        debugPrint(
            'API locations parsed ${raw.length} (data is ${body['data'] is List ? 'List' : body['data'].runtimeType})');
      }
      final list = raw
          .map((e) =>
              LocationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (!filtered) {
        _cache = list;
        _cacheAt = DateTime.now();
      }
      return list;
    } on DioException catch (_) {
      if (AppConstants.allowMockFallback) {
        return _mock();
      }
      rethrow;
    }
  }

  /// كل ids النطاق: نفسه + كل ما تحته في الهرم عبر parentId.
  /// أساس Scope-Based للكاستوديان من scopeLocationId.
  static Set<String> subtreeIds(List<LocationModel> all, String scopeId) {
    final ids = <String>{scopeId};
    var grew = true;
    while (grew) {
      grew = false;
      for (final l in all) {
        if (l.parentId != null && ids.contains(l.parentId) && ids.add(l.id)) {
          grew = true;
        }
      }
    }
    return ids;
  }

  /// Backend contract is {data: [...]}, but a Map-wrapped list
  /// would silently parse as empty — unwrap known keys instead.
  static List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final k in ['locations', 'items', 'results', 'rows', 'data']) {
        if (data[k] is List) return data[k] as List;
      }
    }
    return [];
  }

  /// GET /locations/tree — nested hierarchy read.
  Future<List<LocationModel>> fetchTree() async {
    try {
      final res = await _api.get(AppConstants.locationsTreeEndpoint);
      final body = Map<String, dynamic>.from(res.data as Map);
      final flat = <LocationModel>[];
      void walk(List list, String? parentId) {
        for (final e in list) {
          final m = Map<String, dynamic>.from(e as Map);
          final id = (m['id'] ?? '').toString();
          flat.add(LocationModel.fromJson({...m, 'parentId': m['parentId'] ?? parentId}));
          final children = m['children'];
          if (children is List && children.isNotEmpty) walk(children, id);
        }
      }

      final data = (body['data'] as List? ?? []);
      walk(data, null);
      return flat;
    } on DioException catch (_) {
      if (AppConstants.allowMockFallback) return _mock();
      rethrow;
    }
  }

  /// POST /locations {name, code, type?, parentId?, address?, description?}.
  /// PUT partial. Referenced locations cannot be deleted (409).
  Future<LocationModel> createLocation(Map<String, dynamic> data) async {
    final res = await _api.post(AppConstants.locationsEndpoint, data: data);
    clearCache();
    final body = Map<String, dynamic>.from(res.data as Map);
    return LocationModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<LocationModel> updateLocation(String id, Map<String, dynamic> data) async {
    final res = await _api.put('${AppConstants.locationsEndpoint}/$id', data: data);
    clearCache();
    final body = Map<String, dynamic>.from(res.data as Map);
    return LocationModel.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<void> deleteLocation(String id) async {
    await _api.delete('${AppConstants.locationsEndpoint}/$id');
    clearCache();
  }

  /// Synthetic فقط: مبنيان بكل المستويات.
  List<LocationModel> _mock() => const [
        LocationModel(id: 'campus-1', name: 'Main Campus', level: 'campus'),
        LocationModel(
            id: 'loc-b1', name: 'Building 1', parentId: 'campus-1',
            level: 'building'),
        LocationModel(
            id: 'loc-b2', name: 'Building 2', parentId: 'campus-1',
            level: 'building'),
        LocationModel(
            id: 'loc-b1-f1', name: 'Floor 1', parentId: 'loc-b1',
            level: 'floor'),
        LocationModel(
            id: 'loc-b1-r101', name: 'Room 101', parentId: 'loc-b1-f1',
            level: 'room'),
        LocationModel(
            id: 'loc-b1-r102', name: 'Room 102', parentId: 'loc-b1-f1',
            level: 'room'),
        LocationModel(
            id: 'loc-b2-f2', name: 'Floor 2', parentId: 'loc-b2',
            level: 'floor'),
        LocationModel(
            id: 'loc-b2-r201', name: 'Room 201', parentId: 'loc-b2-f2',
            level: 'room'),
      ];
}
