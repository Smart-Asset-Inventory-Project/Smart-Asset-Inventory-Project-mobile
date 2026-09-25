import 'package:flutter/material.dart';
import '../../core/constants/app_enums.dart';
import '../../core/l10n/strings.dart';
import '../../models/user_model.dart';
import '../assets/assets_list_page.dart';
import '../custody/transfers_page.dart';
import '../maintenance/work_orders_page.dart';
import '../procurement/expiring_warranties_page.dart';
import '../retirement/retirements_page.dart';
import '../../core/services/catalog_service.dart'
    show AuditLogInfo, AuditService;
import '../../core/services/auth_service.dart';
import '../../core/services/work_order_service.dart';
import 'dashboard_stats.dart';

/// AST-FR-08: أقسام الداشبورد حسب الدور.
/// read-only تماما: تعرض بيانات وتفتح شاشات القراءة فقط.
/// الـBackend هو المسؤول الحقيقي عن authorization.
class DashboardSections extends StatefulWidget {
  final UserModel? user;

  /// Shared load from DashboardPage. null = load own (backward compat).
  final Future<DashboardData>? future;

  /// Page-level reload (pull-to-refresh) for the error Retry.
  final Future<void> Function()? onRetry;
  const DashboardSections({super.key, this.user, this.future, this.onRetry});

  @override
  State<DashboardSections> createState() => _DashboardSectionsState();
}

class _DashboardSectionsState extends State<DashboardSections> {
  late Future<DashboardData> _future;

  Future<DashboardData> _ownLoad() => loadDashboardData(
      userId: widget.user?.id,
      scopeLocationId:
          _role == UserRole.custodian ? widget.user?.collegeScope : null,
      includeCustody: _role == UserRole.custodian);

  @override
  void initState() {
    super.initState();
    _future = widget.future ?? _ownLoad();
  }

  @override
  void didUpdateWidget(DashboardSections old) {
    super.didUpdateWidget(old);
    if (old.future != widget.future && widget.future != null) {
      setState(() {
        _future = widget.future!;
      });
    } else if (old.user?.id != widget.user?.id) {
      setState(() {
        _future = widget.future ?? _ownLoad();
      });
    }
  }

  UserRole get _role => widget.user?.role ?? UserRole.unknown;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AuthService.friendlyError(snap.error!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: widget.onRetry == null
                        ? null
                        : () => widget.onRetry!(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData) return const SizedBox.shrink();
        final d = snap.data!;
        switch (_role) {
          case UserRole.admin:
            return Column(children: [
              _statusRow(context, d),
              _dueOverdue(context, d),
              _byCategory(context, d),
              _breakdown(context, d),
              _recentTransfers(context, d),
              _retirements(context, d),
              _lifecycle(context, d),
            ]);
          case UserRole.procurement:
            return Column(children: [
              _valueByCategory(context, d),
              _recentTransfers(context, d),
            ]);
          case UserRole.custodian:
            return Column(children: [
              _confirmAssignment(context, d),
              _myCondition(context, d),
              _breakdown(context, d),
            ]);
          case UserRole.technician:
            return Column(children: [
              _todayQueue(context, d),
            ]);
          case UserRole.auditor:
          case UserRole.unknown:
            return Column(children: [
              _activityTimeline(context, d),
            ]);
        }
      },
    );
  }

  // ---------- shared pieces ----------

  Widget _title(BuildContext context, String key, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(tr(context, key),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(tr(context, 'viewAll')),
            ),
        ],
      ),
    );
  }

  void _go(Widget page) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => page));

  Widget _mini(String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(count,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- admin ----------

  Widget _statusRow(BuildContext context, DashboardData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'statusBreakdown'),
        Row(children: [
          _mini(tr(context, 'active'), '${d.active}',
              Icons.check_circle_outline, Colors.green),
          const SizedBox(width: 8),
          _mini(tr(context, 'inRepair'), '${d.inRepair}',
              Icons.build_outlined, Colors.orange),
          const SizedBox(width: 8),
          _mini(tr(context, 'retired'), '${d.retired}',
              Icons.archive_outlined, Colors.grey),
          const SizedBox(width: 8),
          _mini(tr(context, 'lost'), '${d.lost}',
              Icons.search_off_outlined, Colors.red),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _dueOverdue(BuildContext context, DashboardData d) {
    return Column(children: [
      Row(children: [
        _mini(tr(context, 'maintDue'), '${d.due}',
            Icons.event_available_outlined, Colors.blue),
        const SizedBox(width: 8),
        _mini(tr(context, 'overdue'), '${d.overdue}',
            Icons.warning_amber_outlined, Colors.red),
      ]),
      const SizedBox(height: 20),
    ]);
  }

  Widget _byCategory(BuildContext context, DashboardData d) {
    if (d.byCategory.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'byCategory',
            onViewAll: () => _go(const AssetsListPage())),
        Card(
          child: Column(
            children: d.byCategory.entries
                .map((e) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(tr(context, e.key)),
                      trailing: Text('${e.value}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => _go(AssetsListPage(initialCategory: e.key)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _recentTransfers(BuildContext context, DashboardData d) {    if (d.recentTransfers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'recentTransfers',
            onViewAll: () => _go(const TransfersPage())),
        Card(
          child: Column(
            children: d.recentTransfers
                .map((t) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.swap_horiz),
                      title: Text('${t.assetTag} → ${t.toLocation}',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(t.status),
                      onTap: () => _go(const TransfersPage()),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Retirement requests (admin): count + recent reasons.
  Widget _retirements(BuildContext context, DashboardData d) {
    if (d.retirementRequests == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'retireRequests',
            onViewAll: () => _go(const RetirementsPage())),
        Card(
          child: Column(
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.archive_outlined),
                title: Text('${d.retirementRequests}'),
                subtitle: const Text('requests'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _go(const RetirementsPage()),
              ),
              ...d.recentRetirements.map((r) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.info_outline, size: 18),
                    title: Text(r.assetTag ?? r.assetId,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(r.reason ?? '-',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _lifecycle(BuildContext context, DashboardData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'lifecycle'),
        Card(
          child: ListTile(
            leading:
                const Icon(Icons.archive_outlined, color: Colors.grey),
            title: Text(tr(context, 'retireRequests')),
            subtitle: Text(
                '${d.retired} — ${tr(context, 'readOnlyHint')}'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.verified_outlined,
                color: Colors.teal),
            title: const Text('Warranties expiring (30d)'),
            trailing: Text('${d.expiringWarranties}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: () => _go(const ExpiringWarrantiesPage()),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ---------- procurement ----------

  Widget _valueByCategory(BuildContext context, DashboardData d) {
    if (d.valueByCategory.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'byCategory',
            onViewAll: () => _go(const AssetsListPage())),
        Card(
          child: Column(
            children: d.valueByCategory.entries
                .map((e) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.attach_money),
                      title: Text(tr(context, e.key)),
                      trailing: Text('${e.value.toInt()}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () =>
                          _go(AssetsListPage(initialCategory: e.key)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ---------- custodian ----------

  /// Assets by condition + top locations inside assigned scope.
  Widget _breakdown(BuildContext context, DashboardData d) {
    if (d.byCondition.isEmpty && d.byLocation.isEmpty) {
      return const SizedBox.shrink();
    }
    final locs = d.byLocation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'assets',
            onViewAll: () => _go(const AssetsListPage())),
        Card(
          child: Column(
            children: [
              ...d.byCondition.entries.map((e) => ListTile(
                    dense: true,
                    leading:
                        const Icon(Icons.health_and_safety_outlined),
                    title: Text(tr(context, e.key)),
                    trailing: Text('${e.value}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  )),
              ...locs.take(5).map((e) => ListTile(
                    dense: true,
                    leading:
                        const Icon(Icons.location_city_outlined),
                    title: Text(e.key,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text('${e.value}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _confirmAssignment(BuildContext context, DashboardData d) {
    if (d.pendingToMe == 0 && d.pendingTransfers == 0) {
      return const SizedBox.shrink();
    }
    return Column(children: [
      Card(
        child: ListTile(
          leading: const Icon(Icons.assignment_turned_in_outlined,
              color: Colors.blue),
          title: Text(tr(context, 'confirmAssign')),
          subtitle: Text(
              '${d.pendingToMe} • ${tr(context, 'pendingTransfers')}: ${d.pendingTransfers}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _go(TransfersPage(
              scopeLocationId: widget.user?.collegeScope,
              initialStatus: 'pending')),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.report_outlined, color: Colors.orange),
          title: Text(tr(context, 'reportIssue')),
          subtitle:
              Text('${tr(context, 'needsAttention')}: ${d.myNeedsAttention}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _reportDialog(context),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }

  /// Report condition/missing: files a work order for the asset.
  Future<void> _reportDialog(BuildContext context) async {
    final assetCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String kind = 'damaged';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(tr(context, 'reportIssue')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: assetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'assetId / tag *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  decoration: const InputDecoration(
                    labelText: 'condition',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'damaged', child: Text('damaged')),
                    DropdownMenuItem(
                        value: 'missing', child: Text('missing')),
                    DropdownMenuItem(
                        value: 'needs_repair',
                        child: Text('needs_repair')),
                  ],
                  onChanged: (v) => setD(() => kind = v ?? kind),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'notes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final assetId = assetCtrl.text.trim();
    if (assetId.isEmpty) return;
    try {
      await WorkOrderService().createWorkOrder({
        'assetId': assetId,
        'title': 'Condition report: $kind',
        'priority': 'HIGH',
        if (notesCtrl.text.trim().isNotEmpty)
          'description': '[$kind] ${notesCtrl.text.trim()}',
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _myCondition(BuildContext context, DashboardData d) {
    final good = d.myAssets - d.myNeedsAttention;
    return Column(children: [
      Row(children: [
        _mini(tr(context, 'good'), '$good',
            Icons.check_circle_outline, Colors.green),
        const SizedBox(width: 8),
        _mini(tr(context, 'needsAttention'), '${d.myNeedsAttention}',
            Icons.report_problem_outlined, Colors.orange),
      ]),
      const SizedBox(height: 20),
    ]);
  }

  // ---------- technician ----------

  Widget _todayQueue(BuildContext context, DashboardData d) {
    if (d.todayQueue.isEmpty && d.overdue == 0) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'dueToday',
            onViewAll: () => _go(const WorkOrdersPage(initialStatus: 'due'))),
        Card(
          child: Column(
            children: [
              if (d.overdue > 0)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.warning_amber_outlined,
                      color: Colors.red),
                  title: Text(tr(context, 'overdue')),
                  trailing: Text('${d.overdue}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  onTap: () => _go(const WorkOrdersPage()),
                ),
              ...d.todayQueue.map((w) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.build_outlined),
                    title: Text('${w.id} • ${w.assetId}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${w.priority} • ${w.status}'),
                    onTap: () => _go(const WorkOrdersPage()),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ---------- auditor ----------

  /// سجل التدقيق الحقيقي من /audit-logs، وبديل محلي من الأحداث.
  Widget _activityTimeline(BuildContext context, DashboardData d) {
    return FutureBuilder<List<AuditLogInfo>>(
      future: AuditService().fetchLogs(limit: 8).catchError((_) =>
          <AuditLogInfo>[]),
      builder: (context, snap) {
        final logs = snap.data ?? [];
        final rows = <String>[];
        for (final l in logs) {
          final when = l.createdAt.length >= 10
              ? l.createdAt.substring(0, 10)
              : l.createdAt;
          rows.add('${l.action} ${l.entityType} • ${l.userName ?? ''} • $when');
        }
        if (rows.isEmpty) {
          for (final t in d.recentTransfers) {
            rows.add('${t.assetTag} → ${t.toLocation} (${t.status})');
          }
          for (final w in d.recentClosed) {
            rows.add('${w.id} • ${w.assetId} (${w.status})');
          }
        }
        if (rows.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(context, 'recentActivity',
                onViewAll: () => _go(const TransfersPage())),
            Card(
              child: Column(
                children: rows
                    .map((r) => ListTile(
                          dense: true,
                          leading:
                              const Icon(Icons.history_outlined),
                          title: Text(r,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
