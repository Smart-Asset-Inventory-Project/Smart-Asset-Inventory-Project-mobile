import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Templates')),
      body: FutureBuilder<List<MaintenanceTemplate>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No templates'));
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
                  title: Text(t.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${t.category} • ${t.triggerLabel}'
                    '${due == null ? '' : '\nNext due: ${due.toIso8601String().substring(0, 10)}'}',
                  ),
                  children: t.checklist
                      .map((c) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.check_box_outlined,
                                size: 20),
                            title: Text(c),
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
