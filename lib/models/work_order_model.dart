/// AST-FR-06: أمر الشغل. الإغلاق يحدث history الأصل في الباك اند.
class WorkOrderModel {
  final String id;
  final String assetId;
  final String priority;
  final String status;
  final String? technicianId;
  final String? scheduledDate;
  final String? notes;

  const WorkOrderModel({
    required this.id,
    required this.assetId,
    required this.priority,
    required this.status,
    this.technicianId,
    this.scheduledDate,
    this.notes,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) =>
      WorkOrderModel(
        id: json['id'].toString(),
        assetId: (json['assetId'] ?? '').toString(),
        priority: (json['priority'] ?? 'medium').toString(),
        status: (json['status'] ?? 'open').toString(),
        technicianId: json['technicianId']?.toString(),
        scheduledDate: json['scheduledDate']?.toString(),
        notes: json['notes']?.toString(),
      );
}

/// AST-FR-09: عنصر في طابور المخاطر مع الأسباب. للعرض فقط، لا يغير state.
class RiskItemModel {
  final String assetId;
  final String assetTag;
  final String band; // high, medium, low
  final List<String> reasons;
  final double score;

  const RiskItemModel({
    required this.assetId,
    required this.assetTag,
    required this.band,
    required this.reasons,
    required this.score,
  });

  factory RiskItemModel.fromJson(Map<String, dynamic> json) =>
      RiskItemModel(
        assetId: json['assetId'].toString(),
        assetTag: (json['assetTag'] ?? '').toString(),
        band: (json['band'] ?? 'low').toString(),
        reasons:
            ((json['reasons'] as List?) ?? []).map((e) => e.toString()).toList(),
        score: ((json['score'] as num?) ?? 0).toDouble(),
      );
}
