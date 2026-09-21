import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/asset_service.dart';
import '../../core/services/insights_service.dart';
import '../../core/services/transfer_service.dart';
import '../../core/services/work_order_service.dart';
import '../../models/user_model.dart';

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

class _Stats {
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
}

class _DashboardStatsState extends State<DashboardStats> {
  late Future<_Stats> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(DashboardStats old) {
    super.didUpdateWidget(old);
    if (old.user?.id != widget.user?.id ||
        old.roleOverride != widget.roleOverride) {
      _future = _load();
    }
  }

  Future<_Stats> _load() async {
    final s = _Stats();
    final assets = await AssetService().fetchAssets();
    final orders = await WorkOrderService().fetchWorkOrders();
    final risks = await InsightsService().fetchRiskQueue();
    final transfers = await TransferService().fetchTransfers();
    s.total = assets.length;
    s.value = assets.fold<double>(0, (t, a) => t + (a.purchaseCost ?? 0));
    s.open = orders.where((w) => w.status == 'open').length;
    s.inProgress = orders.where((w) => w.status == 'inProgress').length;
    s.closed = orders.where((w) => w.status == 'closed').length;
    s.due = s.open + s.inProgress;
    s.high = risks.where((r) => r.band == 'high').length;
    s.med = risks.where((r) => r.band == 'medium').length;
    s.low = risks.where((r) => r.band == 'low').length;
    s.pendingTransfers =
        transfers.where((t) => t.status == 'pending').length;
    s.allTransfers = transfers.length;
    final uid = widget.user?.id;
    s.myAssets = uid == null
        ? 0
        : assets.where((a) => a.custodianId == uid).length;
    return s;
  }

  UserRole get _role =>
      widget.roleOverride ?? widget.user?.role ?? UserRole.unknown;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Stats>(
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

  List<Widget> _cardsFor(BuildContext context, _Stats? d) {
    String v(int? n) => d == null ? '…' : '$n';
    switch (_role) {
      case UserRole.procurement:
        return [
          _card(tr(context, 'assetValue'),
              d == null ? '…' : '${d.value.toInt()}', Icons.attach_money),
          _card(tr(context, 'totalAssets'), v(d?.total),
              Icons.inventory_2_outlined),
          _card(tr(context, 'pendingTransfers'), v(d?.pendingTransfers),
              Icons.swap_horiz),
          _card(tr(context, 'openOrders'), v(d?.open), Icons.build_outlined),
        ];
      case UserRole.custodian:
        return [
          _card(tr(context, 'myAssets'), v(d?.myAssets), Icons.person_outline),
          _card(tr(context, 'maintDue'), v(d?.due), Icons.build_outlined),
          _card(tr(context, 'pendingTransfers'), v(d?.pendingTransfers),
              Icons.swap_horiz),
          _card(tr(context, 'highRisk'), v(d?.high),
              Icons.warning_amber_outlined),
        ];
      case UserRole.technician:
        return [
          _card(tr(context, 'openOrders'), v(d?.open), Icons.build_outlined),
          _card(tr(context, 'inProgress'), v(d?.inProgress), Icons.timelapse_outlined),
          _card(tr(context, 'maintDue'), v(d?.due),
              Icons.event_available_outlined),
          _card(tr(context, 'highRisk'), v(d?.high),
              Icons.warning_amber_outlined),
        ];
      case UserRole.auditor:
        return [
          _card(tr(context, 'totalAssets'), v(d?.total),
              Icons.inventory_2_outlined),
          _card(tr(context, 'assetValue'),
              d == null ? '…' : '${d.value.toInt()}', Icons.attach_money),
          _card(tr(context, 'allTransfers'), v(d?.allTransfers), Icons.swap_horiz),
          _card(tr(context, 'closedOrders'), v(d?.closed), Icons.check_circle_outline),
        ];
      case UserRole.admin:
      case UserRole.unknown:
        return [
          _card(tr(context, 'totalAssets'), v(d?.total),
              Icons.inventory_2_outlined),
          _card(tr(context, 'assetValue'),
              d == null ? '…' : '${d.value.toInt()}', Icons.attach_money),
          _card(tr(context, 'maintDue'), v(d?.due), Icons.build_outlined),
          _card(tr(context, 'highRisk'), v(d?.high),
              Icons.warning_amber_outlined),
        ];
    }
  }

  Widget _card(String title, String value, IconData icon) {
    // تحديد لون الكرت بناءً على العنوان للتميز البصري
    Color color = AppColors.blue;
    if (title.contains(tr(context, 'highRisk')) || title.contains('Pending')) color = AppColors.orange;
    if (title.contains(tr(context, 'maintDue')) || title.contains('Open')) color = AppColors.red;
    if (title.contains('Closed')) color = AppColors.green;

    return Container(
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
    );
  }
}
