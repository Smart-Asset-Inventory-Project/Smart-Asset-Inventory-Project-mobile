import 'package:dio/dio.dart';
import '../../models/asset_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-01: هرم Locations.
/// campus > building > college > floor > room > office.
class LocationService {
  LocationService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<LocationModel>> fetchLocations() async {
    try {
      final res = await _api.get(AppConstants.locationsEndpoint);
      final raw = res.data is List
          ? res.data as List
          : (res.data['data'] as List? ?? []);
      return raw
          .map((e) =>
              LocationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (AppConstants.allowMockFallback && e.response == null) {
        return _mock();
      }
      rethrow;
    }
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
