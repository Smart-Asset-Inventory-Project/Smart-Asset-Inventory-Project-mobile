import 'package:flutter/material.dart';
import '../../core/services/retirement_service.dart';
import '../../models/retirement_model.dart';

/// AST-FR-10: قائمة التقاعدات من /retirements (read-only).
class RetirementsPage extends StatefulWidget {
  const RetirementsPage({super.key});

  @override
  State<RetirementsPage> createState() => _RetirementsPageState();
}

class _RetirementsPageState extends State<RetirementsPage> {
  late Future<List<RetirementInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = RetirementService().fetchRetirements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retirements')),
      body: FutureBuilder<List<RetirementInfo>>(
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
            return const Center(child: Text('No retirements'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = items[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.archive_outlined,
                      color: Colors.grey),
                  title: Text(r.assetTag ?? r.assetId,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${r.reason ?? '-'}\n${r.retiredAt ?? ''}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
