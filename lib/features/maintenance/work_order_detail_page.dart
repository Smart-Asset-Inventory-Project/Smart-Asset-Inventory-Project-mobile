import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/work_order_service.dart';
import '../../core/widgets/role_gate.dart';
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
    final closed = w.status == 'closed' || w.status == 'cancelled';
    return Scaffold(
      appBar: AppBar(title: Text('${tr(context, 'workOrder')} ${w.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row(tr(context, 'assets'), w.assetId),
          _row(tr(context, 'priority'), tr(context, w.priority)),
          _row(tr(context, 'status'), tr(context, w.status)),
          _row(tr(context, 'technician'), w.technicianId ?? '-'),
          _row(tr(context, 'scheduled'), w.scheduledDate ?? '-'),
          if (w.completedAt != null)
            _row(tr(context, 'completed'), w.completedAt!),
          if (w.title != null && w.title!.isNotEmpty)
            _row('title', w.title!),
          _row(tr(context, 'notes'), w.notes ?? '-'),
          const Divider(height: 32),
          if (!closed) ...[
            HideForAuditor(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(context, 'closeWorkOrder'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '${tr(context, 'completionNotes')} *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _parts,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr(context, 'partsCost'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _downtime,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr(context, 'downtimeHours'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _close,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(tr(context, 'closeWorkOrder')),
              ),
            ),
                ],
              ),
            ),
          ] else
            Text(tr(context, 'readOnlyOrder')),
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
