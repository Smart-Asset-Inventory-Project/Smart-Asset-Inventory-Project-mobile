import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/asset_service.dart';
import '../../core/services/template_service.dart';
import '../../core/services/work_order_service.dart';
import '../../models/maintenance_template_model.dart';

/// AST-FR-05: عرض قوالب الصيانة + الاستحقاق القادم + checklist.
/// Next due = آخر إكمال لأصل في فئة القالب + frequencyDays (S4).
class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  late Future<(List<MaintenanceTemplate>, Map<String, DateTime>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// آخر completedAt لكل categoryId من أوامر الشغل المغلقة.
  Future<(List<MaintenanceTemplate>, Map<String, DateTime>)> _load() async {
    // Parallel: templates + assets + closed orders in one round.
    final templatesFuture = TemplateService().fetchTemplates();
    final assetsFuture =
        AssetService().fetchAssets().then((v) => v, onError: (_) => []);
    final ordersFuture = WorkOrderService()
        .fetchWorkOrders(status: 'closed')
        .then((v) => v, onError: (_) => []);
    final results = await Future.wait([
      templatesFuture,
      assetsFuture,
      ordersFuture,
    ]);
    final templates = results[0] as List<MaintenanceTemplate>;
    final lastDone = <String, DateTime>{};
    try {
      final assets = results[1] as List;
      final orders = results[2] as List;
      final catOf = {for (final a in assets) a.id: a.categoryId};
      for (final w in orders) {
        final cat = catOf[w.assetId];
        if (cat == null || cat.isEmpty) continue;
        final done = DateTime.tryParse(w.completedAt ?? '');
        if (done == null) continue;
        final prev = lastDone[cat];
        if (prev == null || done.isAfter(prev)) lastDone[cat] = done;
      }
    } catch (_) {}
    return (templates, lastDone);
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
      body: FutureBuilder<(List<MaintenanceTemplate>, Map<String, DateTime>)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('${tr(context, 'error')}: ${snap.error}'));
          }
          final items = snap.data?.$1 ?? [];
          final lastDone = snap.data?.$2 ?? {};
          if (items.isEmpty) {
            return Center(child: Text(tr(context, 'noTemplates')));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = items[i];
              DateTime? done;
              final catId = t.categoryId;
              if (catId != null) done = lastDone[catId];
              final due = done == null || t.intervalDays == null
                  ? t.nextDue
                  : done.add(Duration(days: t.intervalDays!));
              final doneStr = done?.toIso8601String().substring(0, 10);
              return Card(
                child: ExpansionTile(
                  leading: Icon(Icons.event_repeat_outlined,
                      color: _badge(t.triggerType)),
                  title: Text(tr(context, t.name),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${tr(context, t.category)} • ${_triggerText(context, t)}'
                    '${doneStr == null ? '' : '\n${tr(context, 'completed')}: $doneStr'}'
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
