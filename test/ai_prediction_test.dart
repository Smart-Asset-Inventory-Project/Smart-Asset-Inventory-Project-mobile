import 'package:flutter_test/flutter_test.dart';
import 'package:smart_asset_inventory/models/ai_prediction_model.dart';

void main() {
  test('condition maps like the AI example (Good)', () {
    expect(AiPredictRequest.mapCondition('GOOD'), 'Good');
    expect(AiPredictRequest.mapCondition('good'), 'Good');
    expect(AiPredictRequest.mapCondition('DAMAGED'), 'Damaged');
    expect(AiPredictRequest.mapCondition('Fair'), 'Fair');
  });

  test('request serializes the exact 8 contract keys', () {
    const req = AiPredictRequest(
      assetId: 'demo-asset-001',
      assetAgeMonths: 24,
      expectedLifetimeMonths: 60,
      condition: 'Good',
      maintenanceCount: 2,
      recentMaintenanceCount90d: 1,
      downtimeHours90d: 3,
      repairCost90d: 150,
    );
    final j = req.toJson();
    expect(j.keys.toSet(), {
      'asset_id',
      'asset_age_months',
      'expected_lifetime_months',
      'condition',
      'maintenance_count',
      'recent_maintenance_count_90d',
      'downtime_hours_90d',
      'repair_cost_90d',
    });
  });

  test('verified handoff example response parses', () {
    final res = AiPredictResult.fromJson({
      'asset_id': 'demo-asset-001',
      'risk_score': 22.84,
      'risk_level': 'LOW',
      'failure_predicted': false,
      'failure_probability': 0.2284,
      'model_version': 'logistic_regression_v1',
      'is_ai_fallback': false,
      'reasons': [],
    });
    expect(res.riskScore, 22.84);
    expect(res.riskLevel, 'LOW');
    expect(res.failurePredicted, false);
    expect(res.probabilityPercent, closeTo(22.84, 0.001));
    expect(res.isAiFallback, false);
    expect(res.reasons, isEmpty);
  });

  test('missing optional response fields default safely', () {
    final res = AiPredictResult.fromJson({'asset_id': 'x'});
    expect(res.isAiFallback, false);
    expect(res.reasons, isEmpty);
    expect(res.modelVersion, '');
  });
}
