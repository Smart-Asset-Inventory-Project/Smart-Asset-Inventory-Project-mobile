import 'package:flutter/material.dart';
import '../../core/services/work_order_service.dart';
import '../../models/work_order_model.dart';

/// AST-FR-06: تفاصيل الأمر + إغلاق يحدث service history و next due في الباك اند.
class WorkOrderDetailPage extends StatefulWidget {
  final WorkOrderModel workOrder;
  const WorkOrderDetailPage({super.key, required this.workOrder});

  @override
  State<WorkOrderDetailPage> createState() => _WorkOrderDetailPageState();
}

class _WorkOrderDetailPageState extends State<WorkOrderDetailPage> {
  final _notes = TextEditingController();
  final _parts = TextEditingController();
  final _downtime = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _notes.dispose();
    _parts.dispose();
    _downtime.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_notes.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completion notes required')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await WorkOrderService().closeWorkOrder(
        id: widget.workOrder.id,
        notes: _notes.text.trim(),
        partsCost: double.tryParse(_parts.text.trim()),
        downtimeHours: double.tryParse(_downtime.text.trim()),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work order closed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workOrder;
    final closed = w.status == 'closed';
    return Scaffold(
      appBar: AppBar(title: Text('WO ${w.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Asset', w.assetId),
          _row('Priority', w.priority),
          _row('Status', w.status),
          _row('Technician', w.technicianId ?? '-'),
          _row('Scheduled', w.scheduledDate ?? '-'),
          _row('Notes', w.notes ?? '-'),
          const Divider(height: 32),
          if (!closed) ...[
            const Text('Close work order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Completion notes *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _parts,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Parts cost (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _downtime,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Downtime hours (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _close,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Close work order'),
              ),
            ),
          ] else
            const Text('This work order is closed (read-only).'),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
                width: 110,
                child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(
                child: Text(v,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
