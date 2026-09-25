/// Typed contract for the Railway predictive-maintenance AI service.
/// Base: https://smart-asset-ai-production.up.railway.app
/// POST /api/v1/predict — all eight request fields required, no auth.
class AiPredictRequest {
  final String assetId;
  final int assetAgeMonths;
  final int expectedLifetimeMonths;
  final String condition;
  final int maintenanceCount;
  final int recentMaintenanceCount90d;
  final double downtimeHours90d;
  final double repairCost90d;

  const AiPredictRequest({
    required this.assetId,
    required this.assetAgeMonths,
    required this.expectedLifetimeMonths,
    required this.condition,
    required this.maintenanceCount,
    required this.recentMaintenanceCount90d,
    required this.downtimeHours90d,
    required this.repairCost90d,
  });

  /// Backend condition values are free-form (GOOD/FAIR/...); the AI
  /// example uses Title case ("Good"). Known values map explicitly,
  /// anything else is Title-cased as-is — never invented.
  static String mapCondition(String raw) {
    final t = raw.trim().toLowerCase();
    switch (t) {
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      case 'damaged':
        return 'Damaged';
      default:
        if (t.isEmpty) return t;
        return t[0].toUpperCase() + t.substring(1);
    }
  }

  Map<String, dynamic> toJson() => {
        'asset_id': assetId,
        'asset_age_months': assetAgeMonths,
        'expected_lifetime_months': expectedLifetimeMonths,
        'condition': condition,
        'maintenance_count': maintenanceCount,
        'recent_maintenance_count_90d': recentMaintenanceCount90d,
        'downtime_hours_90d': downtimeHours90d,
        'repair_cost_90d': repairCost90d,
      };
}

class AiPredictResult {
  final String assetId;
  final double riskScore;
  final String riskLevel;
  final bool failurePredicted;
  final double failureProbability;
  final String modelVersion;
  final bool isAiFallback;
  final List<String> reasons;

  const AiPredictResult({
    required this.assetId,
    required this.riskScore,
    required this.riskLevel,
    required this.failurePredicted,
    required this.failureProbability,
    required this.modelVersion,
    required this.isAiFallback,
    required this.reasons,
  });

  static double _d(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory AiPredictResult.fromJson(Map<String, dynamic> json) =>
      AiPredictResult(
        assetId: (json['asset_id'] ?? '').toString(),
        riskScore: _d(json['risk_score']),
        riskLevel: (json['risk_level'] ?? '').toString(),
        failurePredicted: json['failure_predicted'] == true,
        failureProbability: _d(json['failure_probability']),
        modelVersion: (json['model_version'] ?? '').toString(),
        isAiFallback: json['is_ai_fallback'] == true,
        reasons: ((json['reasons'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  /// Display percent (probability is 0-1).
  double get probabilityPercent => failureProbability * 100;
}

/// Validation (missing asset fields, HTTP 422 details) and network
/// failures. [details] carries per-field messages when available.
class AiRequestException implements Exception {
  final String message;
  final List<String> details;
  const AiRequestException(this.message, [this.details = const []]);

  @override
  String toString() =>
      details.isEmpty ? message : '$message\n${details.join('\n')}';
}
