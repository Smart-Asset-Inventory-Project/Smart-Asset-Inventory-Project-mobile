import 'package:flutter/material.dart';
import '../../core/services/transfer_service.dart';
import '../../models/transfer_model.dart';
import 'request_transfer_page.dart';

/// AST-FR-04: قائمة النقل + الحالات + طلب جديد.
class TransfersPage extends StatefulWidget {
  const TransfersPage({super.key});

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  late Future<List<TransferModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = TransferService().fetchTransfers();
  }

  void _reload() =>
      setState(() => _future = TransferService().fetchTransfers());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custody Transfers')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Request'),
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RequestTransferPage()),
          );
          if (ok == true) _reload();
        },
      ),
      body: FutureBuilder<List<TransferModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No transfers'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = items[i];
              final color = t.status == 'approved'
                  ? Colors.green
                  : t.status == 'rejected'
                      ? Colors.red
                      : Colors.orange;
              return ListTile(
                leading: Icon(Icons.swap_horiz, color: color),
                title: Text('${t.assetTag} → ${t.toLocation}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${t.fromLocation} → ${t.toLocation}\nby ${t.requestedBy} • ${t.requestedAt.substring(0, 10)}'),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(t.status),
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
