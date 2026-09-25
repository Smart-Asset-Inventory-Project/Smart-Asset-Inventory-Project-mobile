import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/work_order_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/role_gate.dart';
import '../../models/work_order_model.dart';
import 'create_work_order_page.dart';
import 'work_order_detail_page.dart';

/// AST-FR-06: قائمة أوامر الشغل مع فلتر حالة.
/// initialStatus يفتح الصفحة على فلتر جاهز (من كروت الداشبورد).
class WorkOrdersPage extends StatefulWidget {
  final String? initialStatus;

  /// Technician "my orders": server filter when supported,
  /// client filter for due/overdue lists (/due has no user filter).
  final String? assignedToUserId;

  /// Custodian scope: show only orders for these asset ids.
  final Set<String>? assetIds;
  const WorkOrdersPage(
      {super.key,
      this.initialStatus,
      this.assignedToUserId,
      this.assetIds});

  @override
  State<WorkOrdersPage> createState() => _WorkOrdersPageState();
}

class _WorkOrdersPageState extends State<WorkOrdersPage> {
  late String _status;
  late Future<List<WorkOrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus ?? 'all';
    _reload(initial: true);
  }

  void _reload({bool initial = false}) {
    Future<List<WorkOrderModel>> f;
    if (_status == 'due') {
      // GET /work-orders/due scheduling list.
      f = WorkOrderService()
          .fetchDueWorkOrders()
          .then((list) => _forTech(list));
    } else if (_status == 'overdue') {
      f = WorkOrderService()
          .fetchOverdue()
          .then((list) => _forTech(list));
    } else {
      f = WorkOrderService().fetchWorkOrders(
        status: _status == 'all' ? null : _status,
        assignedToUserId: widget.assignedToUserId,
      );
    }
    if (initial) {
      _future = f;
    } else {
      setState(() {
        _future = f;
      });
    }
  }

  /// Client-side tech filter for lists whose endpoint has no user query.
  List<WorkOrderModel> _forTech(List<WorkOrderModel> list) {
    final t = widget.assignedToUserId;
    if (t == null || t.isEmpty) return list;
    return list.where((w) => w.technicianId == t).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'workOrders'))),
      floatingActionButton: HideForAuditor(
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: Text(tr(context, 'add')),
          onPressed: () async {
            final ok = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateWorkOrderPage()),
            );
            if (ok == true) _reload();
          },
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['all', 'due', 'overdue', 'open', 'assigned', 'inProgress', 'closed', 'cancelled']
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tr(context, s)),
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
                  return Center(
                    child: Text(
                        '${tr(context, 'failedRisk')}: ${AuthService.friendlyError(snap.error!)}'),
                  );
                }
                final items = _visible(snap.data ?? []);
                if (items.isEmpty) {
                  return Center(child: Text(tr(context, 'noWorkOrders')));
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final w = items[i];
                    final pColor = w.priority == 'high'
                        ? AppColors.red
                        : w.priority == 'medium'
                            ? AppColors.orange
                            : AppColors.blue;
                    final sColor = w.status == 'closed'
                        ? AppColors.green
                        : w.status == 'open'
                            ? AppColors.red
                            : AppColors.orange;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: pColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            w.status == 'closed'
                                ? Icons.check_circle_outline
                                : Icons.build_outlined,
                            color: pColor,
                          ),
                        ),
                        title: Text('${w.id} • ${w.assetId}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                                '${tr(context, 'scheduled')}: ${w.scheduledDate ?? '-'}',
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _badge(tr(context, w.priority), pColor),
                                const SizedBox(width: 6),
                                _badge(tr(context, w.status), sColor),
                              ],
                            ),
                          ],
                        ),
                        trailing:
                            const Icon(Icons.chevron_right_outlined, size: 20),
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkOrderDetailPage(workOrder: w),
                            ),
                          );
                          if (changed == true) _reload();
                        },
                      ),
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

  /// Client-side scope filter — same asset set the dashboard card counts.
  List<WorkOrderModel> _visible(List<WorkOrderModel> items) {
    if (widget.assetIds == null) return items;
    return items.where((w) => widget.assetIds!.contains(w.assetId)).toList();
  }

  Widget _badge(String text, Color color) {    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
