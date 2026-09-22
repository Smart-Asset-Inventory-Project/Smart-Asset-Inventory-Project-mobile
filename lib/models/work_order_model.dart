/// AST-FR-06: أمر شغل الباك اند.
/// status: OPEN/IN_PROGRESS/COMPLETED/CANCELLED -> open/inProgress/closed/cancelled.
/// dueDate, assignedToUserId, title, template.
class WorkOrderModel {
  final String id;
  final String assetId;
  final String priority;
  final String status;
  final String? technicianId;
  final String? scheduledDate;
  final String? completedAt;
  final String? notes;
  final String? title;

  const WorkOrderModel({
    required this.id,
    required this.assetId,
    required this.priority,
    required this.status,
    this.technicianId,
    this.scheduledDate,
    this.completedAt,
    this.notes,
    this.title,
  });

  static String _normStatus(String s) {
    switch (s.toUpperCase().replaceAll('_', '')) {
      case 'OPEN':
        return 'open';
      case 'INPROGRESS':
        return 'inProgress';
      case 'COMPLETED':
      case 'CLOSED':
        return 'closed';
      case 'CANCELLED':
        return 'cancelled';
      default:
        return s.toLowerCase();
    }
  }

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) =>
      WorkOrderModel(
        id: json['id'].toString(),
        assetId: (json['assetId'] ?? '').toString(),
        priority: (json['priority'] ?? 'medium').toString().toLowerCase(),
        status: _normStatus((json['status'] ?? 'open').toString()),
        technicianId: (json['assignedToUserId'] ?? json['technicianId'])
            ?.toString(),
        scheduledDate:
            (json['dueDate'] ?? json['scheduledDate'])?.toString(),
        completedAt: json['completedAt']?.toString(),
        notes: (json['description'] ?? json['notes'])?.toString(),
        title: json['title']?.toString(),
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
