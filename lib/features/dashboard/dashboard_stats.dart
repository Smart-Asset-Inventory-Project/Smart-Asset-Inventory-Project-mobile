import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/asset_service.dart';
import '../../core/services/insights_service.dart';
import '../../core/services/transfer_service.dart';
import '../../core/services/work_order_service.dart';
import '../../models/transfer_model.dart';
import '../../models/user_model.dart';
import '../../models/work_order_model.dart';
import '../../core/services/catalog_service.dart' show DashboardApi;
import '../assets/assets_list_page.dart';
import '../custody/transfers_page.dart';
import '../maintenance/work_orders_page.dart';
import '../procurement/procurement_overview_page.dart';
import '../risk/risk_queue_page.dart';

/// AST-FR-08: داشبورد حسب الدور بدل الأرقام الثابتة.
/// admin / procurement / custodian / technician / auditor.
/// Totals reconcile: نفس القوائم المستخدمة في الشاشات.
class DashboardStats extends StatefulWidget {
  final UserModel? user;

  /// معاينة ديمو للدور. null = دور المستخدم الحقيقي.
  final UserRole? roleOverride;
  const DashboardStats({super.key, this.user, this.roleOverride});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

/// بيانات الداشبورد المجمعة.
/// /dashboard/summary يعطي إجماليات السيرفر الكاملة، والقوائم للتفاصيل.
class DashboardData {
  int total = 0;
  double value = 0;
  int due = 0;
  int high = 0;
  int med = 0;
  int low = 0;
  int open = 0;
  int inProgress = 0;
  int closed = 0;
  int pendingTransfers = 0;
  int allTransfers = 0;
  int myAssets = 0;
  int active = 0;
  int inRepair = 0;
  int retired = 0;
  int lost = 0;
  int overdue = 0;
  int dueToday = 0;
  int dueSoon = 0;
  int expiringWarranties = 0;
  int myOpenOrders = 0;
  int myNeedsAttention = 0;
  int pendingToMe = 0;
  Map<String, int> byCategory = {};
  Map<String, double> valueByCategory = {};
  List<TransferModel> recentTransfers = [];
  List<WorkOrderModel> todayQueue = [];
  List<WorkOrderModel> recentClosed = [];
}

String normAssetStatus(String s) {
  final t = s.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
  if (t == 'active') return 'active';
  if (t.contains('repair') || t.contains('maintenance')) return 'inRepair';
  if (t.contains('retir')) return 'retired';
  if (t.contains('lost') || t.contains('missing')) return 'lost';
  return 'other';
}

DateTime? _day(String? iso) {
  if (iso == null) return null;
  final d = DateTime.tryParse(iso);
  if (d == null) return null;
  return DateTime(d.year, d.month, d.day);
}

/// المصدر الوحيد لبيانات الداشبورد (stats + sections).
Future<DashboardData> loadDashboardData(
    {String? userId, String? scopeLocationId}) async {
  final s = DashboardData();
  final assets = await AssetService().fetchAssets(
    scopeLocationId: scopeLocationId,
  );
  var orders = await WorkOrderService().fetchWorkOrders();
  // Scope-Based: أوامر أصول النطاق فقط للكاستوديان.
  if (scopeLocationId != null && scopeLocationId.isNotEmpty) {
    final ids = assets.map((a) => a.id).toSet();
    orders = orders.where((w) => ids.contains(w.assetId)).toList();
  }
  final risks = await InsightsService().fetchRiskQueue();
  final transfers = await TransferService().fetchTransfers();
  final today = DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);

  s.total = assets.length;
  s.value = assets.fold<double>(0, (t, a) => t + (a.purchaseCost ?? 0));
  for (final a in assets) {
    switch (normAssetStatus(a.status)) {
      case 'active':
        s.active++;
        break;
      case 'inRepair':
        s.inRepair++;
        break;
      case 'retired':
        s.retired++;
        break;
      case 'lost':
        s.lost++;
        break;
    }
    s.byCategory[a.category] = (s.byCategory[a.category] ?? 0) + 1;
    s.valueByCategory[a.category] =
        (s.valueByCategory[a.category] ?? 0) + (a.purchaseCost ?? 0);
    if (userId != null &&
        a.custodianId == userId &&
        a.condition.toLowerCase() != 'good') {
      s.myNeedsAttention++;
    }
  }
  for (final w in orders) {
    final st = w.status;
    if (st == 'open') s.open++;
    if (st == 'inProgress') s.inProgress++;
    if (st == 'closed') s.closed++;
    final day = _day(w.scheduledDate);
    if ((st == 'open' || st == 'inProgress') && day != null) {
      if (day.isBefore(todayDay)) s.overdue++;
      if (day == todayDay) {
        s.dueToday++;
        s.todayQueue.add(w);
      }
    }
    if (userId != null &&
        w.technicianId == userId &&
        (st == 'open' || st == 'inProgress')) {
      s.myOpenOrders++;
    }
  }
  s.due = s.open + s.inProgress;
  // إجماليات السيرفر الكاملة من /dashboard/summary (تغطي ما بعد limit).
  // تُطبق فقط بدون scope: الكاستوديان يرى نطاقه المحسوب محليا.
  if (scopeLocationId == null || scopeLocationId.isEmpty) {
    try {
      final summary = await DashboardApi().fetchSummary();
      if (summary != null) {
        s.total = summary.totalAssets;
        s.active = summary.activeAssets;
        s.inRepair = summary.maintenanceAssets;
        s.retired = summary.retiredAssets;
        s.open = summary.openWorkOrders;
        s.overdue = summary.overdueWorkOrders;
        s.dueSoon = summary.dueSoonWorkOrders;
        s.due = s.open + s.inProgress;
        s.value = summary.totalValue;
        s.expiringWarranties = summary.expiringWarranties30d;
      }
    } catch (_) {
      // يبقى المحسوب محليا
    }
  }
  s.high = risks.where((r) => r.band == 'high').length;
  s.med = risks.where((r) => r.band == 'medium').length;
  s.low = risks.where((r) => r.band == 'low').length;
  s.pendingTransfers = transfers.where((t) => t.status == 'pending').length;
  s.allTransfers = transfers.length;
  s.pendingToMe = userId == null
      ? 0
      : transfers
          .where((t) => t.status == 'pending' && t.toCustodian == userId)
          .length;
  s.myAssets = userId == null
      ? 0
      : scopeLocationId != null && scopeLocationId.isNotEmpty
          // Scope-Based: أصول النطاق كله بدل عهدة المستخدم فقط
          ? assets.length
          : assets.where((a) => a.custodianId == userId).length;
  s.recentTransfers = transfers.take(4).toList();
  s.recentClosed =
      orders.where((w) => w.status == 'closed').take(3).toList();
  return s;
}

class _DashboardStatsState extends State<DashboardStats> {
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = loadDashboardData(userId: widget.user?.id, scopeLocationId: _role == UserRole.custodian ? widget.user?.collegeScope : null);
  }

  @override
  void didUpdateWidget(DashboardStats old) {
    super.didUpdateWidget(old);
    if (old.user?.id != widget.user?.id ||
        old.roleOverride != widget.roleOverride) {
      _future = loadDashboardData(userId: widget.user?.id, scopeLocationId: _role == UserRole.custodian ? widget.user?.collegeScope : null);
    }
  }

  UserRole get _role =>
      widget.roleOverride ?? widget.user?.role ?? UserRole.unknown;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _future,
      builder: (context, snap) {
        final d = snap.data;
        final cards = _cardsFor(context, d);
        return Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // نسبة أقل = خلايا أطول حتى لا يفيض النص على الموبايل
              childAspectRatio: 1.3,
              children: cards,
            ),
            const SizedBox(height: 12),
            // if (d != null && _role != UserRole.procurement)
            //   Text(
            //     'High ${d.high} • Med ${d.med} • Low ${d.low} (tap rows for reasons)',
            //     style: const TextStyle(color: Colors.grey, fontSize: 12),
            //   ),
          ],
        );
      },
    );
  }

  /// كل كارت يفتح الشاشة المسؤولة عنه.
  void _go(Widget page) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => page));

  List<Widget> _cardsFor(BuildContext context, DashboardData? d) {
    String v(int? n) => d == null ? '…' : '$n';
    switch (_role) {
      case UserRole.procurement:
        return [
          _card(tr(context, 'assetValue'),
              d == null ? '…' : '${d.value.toInt()}', Icons.attach_money,
              onTap: () => _go(const ProcurementOverviewPage())),
          _card(tr(context, 'totalAssets'), v(d?.total),
              Icons.inventory_2_outlined,
              onTap: () => _go(const AssetsListPage())),
          _card(tr(context, 'pendingTransfers'), v(d?.pendingTransfers),
              Icons.swap_horiz,
              onTap: () => _go(const TransfersPage())),
          _card(tr(context, 'openOrders'), v(d?.open), Icons.build_outlined,
              onTap: () =>
                  _go(const WorkOrdersPage(initialStatus: 'open'))),
        ];
      case UserRole.custodian:
        return [
          _card(tr(context, 'myAssets'), v(d?.myAssets), Icons.person_outline,
              onTap: () => _go(AssetsListPage(
                  scopeLocationId: widget.user?.collegeScope))),
          _card(tr(context, 'maintDue'), v(d?.due), Icons.build_outlined,
              onTap: () => _go(const WorkOrdersPage())),
          _card(tr(context, 'pendingTransfers'), v(d?.pendingTransfers),
              Icons.swap_horiz,
              onTap: () => _go(const TransfersPage())),
          _card(tr(context, 'needsAttention'), v(d?.myNeedsAttention),
              Icons.report_problem_outlined,
              onTap: () => _go(AssetsListPage(
                  scopeLocationId: widget.user?.collegeScope))),
        ];
      case UserRole.technician:
        return [
          _card(tr(context, 'myOrders'), v(d?.myOpenOrders),
              Icons.assignment_ind_outlined,
              onTap: () =>
                  _go(const WorkOrdersPage(initialStatus: 'open'))),
          _card(tr(context, 'dueToday'), v(d?.dueToday),
              Icons.today_outlined,
              onTap: () => _go(const WorkOrdersPage())),
          _card(tr(context, 'overdue'), v(d?.overdue),
              Icons.warning_amber_outlined,
              onTap: () => _go(const WorkOrdersPage())),
          _card(tr(context, 'completed'), v(d?.closed),
              Icons.check_circle_outline,
              onTap: () =>
                  _go(const WorkOrdersPage(initialStatus: 'closed'))),
        ];
      case UserRole.auditor:
        return [
          _card(tr(context, 'totalAssets'), v(d?.total),
              Icons.inventory_2_outlined,
              onTap: () => _go(const AssetsListPage())),
          _card(tr(context, 'assetValue'),
              d == null ? '…' : '${d.value.toInt()}', Icons.attach_money,
              onTap: () => _go(const ProcurementOverviewPage())),
          _card(tr(context, 'allTransfers'), v(d?.allTransfers), Icons.swap_horiz,
              onTap: () => _go(const TransfersPage())),
          _card(tr(context, 'closedOrders'), v(d?.closed), Icons.check_circle_outline,
              onTap: () =>
                  _go(const WorkOrdersPage(initialStatus: 'closed'))),
        ];
      case UserRole.admin:
      case UserRole.unknown:
        return [
          _card(tr(context, 'totalAssets'), v(d?.total),
              Icons.inventory_2_outlined,
              onTap: () => _go(const AssetsListPage())),
          _card(tr(context, 'assetValue'),
              d == null ? '…' : '${d.value.toInt()}', Icons.attach_money,
              onTap: () => _go(const ProcurementOverviewPage())),
          _card(tr(context, 'maintDue'), v(d?.due), Icons.build_outlined,
              onTap: () => _go(const WorkOrdersPage())),
          _card(tr(context, 'highRisk'), v(d?.high),
              Icons.warning_amber_outlined,
              onTap: () =>
                  _go(const RiskQueuePage(riskBand: 'high'))),
        ];
    }
  }

  Widget _card(String title, String value, IconData icon,
      {VoidCallback? onTap}) {
    // تحديد لون الكرت بناءً على العنوان للتميز البصري
    Color color = AppColors.blue;
    if (title.contains(tr(context, 'highRisk')) || title.contains('Pending')) color = AppColors.orange;
    if (title.contains(tr(context, 'maintDue')) || title.contains('Open')) color = AppColors.red;
    if (title.contains('Closed')) color = AppColors.green;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // خط ملون جانبي للتميز
          Positioned(
            left: Localizations.localeOf(context).languageCode == 'ar' ? null : 0,
            right: Localizations.localeOf(context).languageCode == 'ar' ? 0 : null,
            top: 20,
            bottom: 20,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 28, color: color),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.trending_up, size: 14, color: color),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
