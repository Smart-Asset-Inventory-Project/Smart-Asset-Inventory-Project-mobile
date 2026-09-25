import 'dart:convert';

/// AST-FR-05: قالب صيانة الباك اند.
/// {id,name,description,frequencyDays,tasks(JSON string),categoryId}.
class MaintenanceTemplate {
  final String id;
  final String name;
  final String category; // اسم الفئة أو نطاقها
  final String? categoryId;
  final String? description;
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
    this.categoryId,
    this.description,
    required this.triggerType,
    this.intervalDays,
    this.runtimeHours,
    this.conditionRule,
    this.checklist = const [],
    this.lastServiceDate,
  });

  static List<String> _tasks(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      try {
        final d = jsonDecode(raw);
        if (d is List) return d.map((e) => e.toString()).toList();
      } catch (_) {}
      return [raw];
    }
    return [];
  }

  factory MaintenanceTemplate.fromJson(Map<String, dynamic> json) {
    // Docs: triggerType TIME_BASED|MANUAL, frequencyDays, tasks array in /
    // JSON-text out. Legacy app values calendar/runtime/condition kept.
    final rawTrigger = (json['triggerType'] ?? 'calendar').toString();
    final trigger = rawTrigger == 'TIME_BASED'
        ? 'calendar'
        : rawTrigger == 'MANUAL'
            ? 'condition'
            : rawTrigger;
    return MaintenanceTemplate(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        category: (json['category'] ?? json['categoryId'] ?? '').toString(),
        categoryId: json['categoryId']?.toString(),
        description: json['description']?.toString(),
        triggerType: trigger,
        intervalDays: (json['frequencyDays'] ?? json['intervalDays'] as num?)
            ?.toInt(),
        runtimeHours: (json['runtimeHours'] as num?)?.toInt(),
        conditionRule: json['conditionRule']?.toString(),
        checklist: _tasks(json['tasks'] ?? json['checklist']),
        lastServiceDate: json['lastServiceDate']?.toString(),
      );
  }

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
