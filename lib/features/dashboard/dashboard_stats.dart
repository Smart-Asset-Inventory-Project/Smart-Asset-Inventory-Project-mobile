import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import '../../core/services/insights_service.dart';
import '../../core/services/work_order_service.dart';

/// AST-FR-08: إحصائيات حقيقية من السيرفس بدل الأرقام الثابتة.sam
/// Totals reconcile: نفس القوائم المستخدمة في الشاشات.
class DashboardStats extends StatefulWidget {
  const DashboardStats({super.key});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  late Future<({int total, double value, int due, int high, int med, int low})>
      _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({int total, double value, int due, int high, int med, int low})>
      _load() async {
    final assets = await AssetService().fetchAssets();
    final orders = await WorkOrderService().fetchWorkOrders();
    final risks = await InsightsService().fetchRiskQueue();
    final total = assets.length;
    final value = assets.fold<double>(
        0, (s, a) => s + (a.purchaseCost ?? 0));
    final due =
        orders.where((w) => w.status == 'open' || w.status == 'inProgress').length;
    final high = risks.where((r) => r.band == 'high').length;
    final med = risks.where((r) => r.band == 'medium').length;
    final low = risks.where((r) => r.band == 'low').length;
    return (total: total, value: value, due: due, high: high, med: med, low: low);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        ({int total, double value, int due, int high, int med, int low})>(
      future: _future,
      builder: (context, snap) {
        final d = snap.data;
        return Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _card('Total Assets', d == null ? '…' : '${d.total}',
                    Icons.inventory_2_outlined),
                _card('Asset Value', d == null ? '…' : '${d.value.toInt()}',
                    Icons.attach_money),//هو حاليًا إجمالي  تكلفة الشراء المسجل في قاعدة البيانات.
                _card('Maintenance Due', d == null ? '…' : '${d.due}',
                    Icons.build_outlined),
                _card('High Risk', d == null ? '…' : '${d.high}',
                    Icons.warning_amber_outlined),
              ],
            ),
            const SizedBox(height: 12),
            if (d != null)
              Text(
                'High ${d.high} • Med ${d.med} • Low ${d.low} (tap card for reasons)',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        );
      },
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 28, color: Colors.blue),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
