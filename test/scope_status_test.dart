import 'package:flutter_test/flutter_test.dart';
import 'package:smart_asset_inventory/core/services/location_service.dart';
import 'package:smart_asset_inventory/features/dashboard/dashboard_stats.dart'
    show normAssetStatus;
import 'package:smart_asset_inventory/models/asset_model.dart';

void main() {
  group('normAssetStatus maps backend values', () {
    test('ACTIVE/MAINTENANCE/RETIRED/LOST', () {
      expect(normAssetStatus('ACTIVE'), 'active');
      expect(normAssetStatus('active'), 'active');
      expect(normAssetStatus('MAINTENANCE'), 'inRepair');
      expect(normAssetStatus('in_maintenance'), 'inRepair');
      expect(normAssetStatus('RETIRED'), 'retired');
      expect(normAssetStatus('LOST'), 'lost');
      expect(normAssetStatus('missing'), 'lost');
      expect(normAssetStatus('???'), 'other');
    });
  });

  group('LocationService.subtreeIds', () {
    const locs = [
      LocationModel(id: 'campus', name: 'Campus', level: 'campus'),
      LocationModel(
          id: 'b1', name: 'B1', parentId: 'campus', level: 'building'),
      LocationModel(
          id: 'f1', name: 'F1', parentId: 'b1', level: 'floor'),
      LocationModel(
          id: 'r1', name: 'R1', parentId: 'f1', level: 'room'),
      LocationModel(
          id: 'b2', name: 'B2', parentId: 'campus', level: 'building'),
    ];

    test('scope includes self + all descendants only', () {
      final sub = LocationService.subtreeIds(locs, 'b1');
      expect(sub, {'b1', 'f1', 'r1'});
    });

    test('leaf scope is itself', () {
      expect(LocationService.subtreeIds(locs, 'r1'), {'r1'});
    });

    test('root scope is everything', () {
      expect(LocationService.subtreeIds(locs, 'campus'),
          {'campus', 'b1', 'f1', 'r1', 'b2'});
    });
  });
}
