/// GET/POST /service-events. Money in as number, out as string.
/// cost must equal labor + parts. Cancelled work orders reject service.
class ServiceEvent {
  final String id;
  final String workOrderId;
  final String? laborCost;
  final String? partsCost;
  final double? downtimeHours;
  final String outcome;
  final String? notes;
  final String? cost;

  const ServiceEvent({
    required this.id,
    required this.workOrderId,
    this.laborCost,
    this.partsCost,
    this.downtimeHours,
    required this.outcome,
    this.notes,
    this.cost,
  });

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory ServiceEvent.fromJson(Map<String, dynamic> json) => ServiceEvent(
        id: json['id'].toString(),
        workOrderId: (json['workOrderId'] ?? '').toString(),
        laborCost: json['laborCost']?.toString(),
        partsCost: json['partsCost']?.toString(),
        downtimeHours: _d(json['downtimeHours']),
        outcome: (json['outcome'] ?? 'completed').toString(),
        notes: json['notes']?.toString(),
        cost: json['cost']?.toString(),
      );
}
