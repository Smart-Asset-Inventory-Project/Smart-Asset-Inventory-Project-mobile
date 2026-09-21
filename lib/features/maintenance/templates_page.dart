import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/template_service.dart';
import '../../models/maintenance_template_model.dart';

/// AST-FR-05: عرض قوالب الصيانة + الاستحقاق القادم + checklist.
class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  late Future<List<MaintenanceTemplate>> _future;

  @override
  void initState() {
    super.initState();
    _future = TemplateService().fetchTemplates();
  }

  Color _badge(String type) {
    switch (type) {
      case 'calendar':
        return Colors.blue;
      case 'runtime':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  String _triggerText(BuildContext context, MaintenanceTemplate t) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    switch (t.triggerType) {
      case 'calendar':
        return isAr
            ? 'كل ${t.intervalDays ?? '-'} يوم'
            : 'Every ${t.intervalDays ?? '-'} days';
      case 'runtime':
        return isAr
            ? 'كل ${t.runtimeHours ?? '-'} ساعة تشغيل'
            : 'Every ${t.runtimeHours ?? '-'} hrs';
      default:
        return tr(context, t.conditionRule ?? 'condition');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'templates'))),
      body: FutureBuilder<List<MaintenanceTemplate>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('${tr(context, 'error')}: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(child: Text(tr(context, 'noTemplates')));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = items[i];
              final due = t.nextDue;
              return Card(
                child: ExpansionTile(
                  leading: Icon(Icons.event_repeat_outlined,
                      color: _badge(t.triggerType)),
                  title: Text(tr(context, t.name),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${tr(context, t.category)} • ${_triggerText(context, t)}'
                    '${due == null ? '' : '\n${tr(context, 'nextDue')}: ${due.toIso8601String().substring(0, 10)}'}',
                  ),
                  children: t.checklist
                      .map((c) => ListTile(
                            dense: true,
                            leading:
                                const Icon(Icons.check_box_outlined, size: 20),
                            title: Text(tr(context, c)),
                          ))
                      .toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
