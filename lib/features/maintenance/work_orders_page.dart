import 'package:flutter/material.dart';
import '../../core/services/work_order_service.dart';
import '../../models/work_order_model.dart';
import 'work_order_detail_page.dart';

/// AST-FR-06: قائمة أوامر الشغل مع فلتر حالة.
class WorkOrdersPage extends StatefulWidget {
  const WorkOrdersPage({super.key});

  @override
  State<WorkOrdersPage> createState() => _WorkOrdersPageState();
}

class _WorkOrdersPageState extends State<WorkOrdersPage> {
  String _status = 'all';
  late Future<List<WorkOrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = WorkOrderService().fetchWorkOrders(
          status: _status == 'all' ? null : _status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Orders')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['all', 'open', 'inProgress', 'closed']
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: _status == s,
                          onSelected: (_) {
                            _status = s;
                            _reload();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<WorkOrderModel>>(
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
                  return const Center(child: Text('No work orders'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final w = items[i];
                    return ListTile(
                      leading: Icon(
                        w.status == 'closed'
                            ? Icons.check_circle
                            : Icons.build_outlined,
                        color: w.priority == 'high'
                            ? Colors.red
                            : Colors.blue,
                      ),
                      title: Text('${w.id} • ${w.assetId}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${w.priority} • ${w.status} • ${w.scheduledDate ?? '-'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final changed = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkOrderDetailPage(workOrder: w),
                          ),
                        );
                        if (changed == true) _reload();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
