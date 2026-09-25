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
  final _labor = TextEditingController();
  final _outcome = TextEditingController();
  final _downtime = TextEditingController();
  bool _loading = false;
  String? _statusOverride;

  @override
  void dispose() {
    _notes.dispose();
    _parts.dispose();
    _labor.dispose();
    _outcome.dispose();
    _downtime.dispose();
    super.dispose();
  }

  String get _status => _statusOverride ?? widget.workOrder.status;

  Future<void> _changeStatus(String status, {String? assignedToUserId}) async {
    setState(() => _loading = true);
    try {
      await WorkOrderService().updateStatus(
        widget.workOrder.id,
        status,
        assignedToUserId: assignedToUserId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status → $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assignDialog() async {
    final ctrl = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign technician'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'assignedToUserId *',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
    if (id != null && id.isNotEmpty) {
      await _changeStatus('ASSIGNED', assignedToUserId: id);
    }
  }

  Future<void> _cancelDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel work order?'),
        content: const Text('Nonterminal orders may move to CANCELLED.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel order',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await _changeStatus('CANCELLED');
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
        laborCost: double.tryParse(_labor.text.trim()),
        partsCost: double.tryParse(_parts.text.trim()),
        downtimeHours: double.tryParse(_downtime.text.trim()),
        outcome: _outcome.text.trim().isEmpty ? null : _outcome.text.trim(),
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
    final st = _status;
    final closed = st == 'closed' || st == 'cancelled';
    return Scaffold(
      appBar: AppBar(title: Text('${tr(context, 'workOrder')} ${w.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row(tr(context, 'assets'), w.assetId),
          _row(tr(context, 'priority'), tr(context, w.priority)),
          _row(tr(context, 'status'), tr(context, st)),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lifecycle: OPEN → ASSIGNED → IN_PROGRESS → COMPLETED.
                  if (st == 'open') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text('Assign'),
                            onPressed: _loading ? null : _assignDialog,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.play_arrow_outlined),
                            label: const Text('Start'),
                            onPressed: _loading
                                ? null
                                : () => _changeStatus('IN_PROGRESS'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (st == 'assigned')
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.play_arrow_outlined),
                        label: const Text('Start progress'),
                        onPressed: _loading
                            ? null
                            : () => _changeStatus('IN_PROGRESS'),
                      ),
                    ),
                  if (st == 'assigned') const SizedBox(height: 12),
                  Text(tr(context, 'closeWorkOrder'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _outcome,
              decoration: const InputDecoration(
                labelText: 'outcome (default: notes)',
                border: OutlineInputBorder(),
              ),
            ),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labor,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'laborCost',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _parts,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr(context, 'partsCost'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
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
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('Cancel order',
                  style: TextStyle(color: Colors.red)),
              onPressed: _loading ? null : _cancelDialog,
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
