import 'package:flutter/material.dart';
import '../../core/services/insights_service.dart';
import '../../models/work_order_model.dart';

/// AST-FR-09: طابور المخاطر للعرض فقط مع الأسباب.
/// لا يغير state أصل أو أمر شغل؛ يتطلب تأكيد بشري في الباك اند.
class RiskQueuePage extends StatefulWidget {
  const RiskQueuePage({super.key});

  @override
  State<RiskQueuePage> createState() => _RiskQueuePageState();
}

class _RiskQueuePageState extends State<RiskQueuePage> {
  late Future<List<RiskItemModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = InsightsService().fetchRiskQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Risk Queue')),
      body: FutureBuilder<List<RiskItemModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No risks'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              final color = r.band == 'high'
                  ? Colors.red
                  : r.band == 'medium'
                      ? Colors.orange
                      : Colors.green;
              return ListTile(
                leading: Icon(Icons.warning, color: color),
                title: Text('${r.assetTag} • ${r.band}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'score ${r.score.toStringAsFixed(2)}\n${r.reasons.join(' • ')}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
