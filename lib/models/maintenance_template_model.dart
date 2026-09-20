/// AST-FR-05: قالب صيانة حسب الفئة أو الموديل.
/// calendar/runtime/condition trigger + حساب next due من آخر خدمة.
class MaintenanceTemplate {
  final String id;
  final String name;
  final String category; // نطاق الفئة أو الموديل
  final String triggerType; // calendar, runtime, condition
  final int? intervalDays;
  final int? runtimeHours;
  final String? conditionRule;
  final List<String> checklist;
  final String? lastServiceDate; // yyyy-MM-dd

  const MaintenanceTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.triggerType,
    this.intervalDays,
    this.runtimeHours,
    this.conditionRule,
    this.checklist = const [],
    this.lastServiceDate,
  });

  factory MaintenanceTemplate.fromJson(Map<String, dynamic> json) =>
      MaintenanceTemplate(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        triggerType: (json['triggerType'] ?? 'calendar').toString(),
        intervalDays: (json['intervalDays'] as num?)?.toInt(),
        runtimeHours: (json['runtimeHours'] as num?)?.toInt(),
        conditionRule: json['conditionRule']?.toString(),
        checklist: ((json['checklist'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        lastServiceDate: json['lastServiceDate']?.toString(),
      );

  /// تاريخ الاستحقاق القادم من القالب + آخر خدمة (calendar trigger).
  DateTime? get nextDue {
    if (triggerType != 'calendar') return null;
    if (intervalDays == null) return null;
    DateTime base;
    if (lastServiceDate != null) {
      base = DateTime.tryParse(lastServiceDate!) ?? DateTime.now();
    } else {
      base = DateTime.now();
    }
    return base.add(Duration(days: intervalDays!));
  }

  String get triggerLabel {
    switch (triggerType) {
      case 'calendar':
        return 'Every ${intervalDays ?? '-'} days';
      case 'runtime':
        return 'Every ${runtimeHours ?? '-'} hrs';
      default:
        return conditionRule ?? 'Condition based';
    }
  }
}
