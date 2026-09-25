import 'package:flutter/material.dart';
import 'package:smart_asset_inventory/core/theme/app_colors.dart';

import '../../core/l10n/strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/insights_service.dart';
import '../risk/risk_queue_page.dart';
import 'dashboard_stats.dart' show DashboardData;

class DashboardRiskSection extends StatefulWidget {
  /// Shared dashboard load — counts derived with zero extra requests.
  /// null = fetch own (backward compat for direct RiskQueue use).
  final Future<DashboardData>? future;
  const DashboardRiskSection({super.key, this.future});

  @override
  State<DashboardRiskSection> createState() => _DashboardRiskSectionState();
}

class _DashboardRiskSectionState extends State<DashboardRiskSection> {
  late Future<({int high, int medium, int low})> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadRisk();
  }

  @override
  void didUpdateWidget(DashboardRiskSection old) {
    super.didUpdateWidget(old);
    if (old.future != widget.future) {
      setState(() {
        _future = _loadRisk();
      });
    }
  }

  Future<({int high, int medium, int low})> _loadRisk() async {
    // Shared load: reuse dashboard data, no extra network.
    final shared = widget.future;
    if (shared != null) {
      final d = await shared;
      return (high: d.high, medium: d.med, low: d.low);
    }
    final risks = await InsightsService().fetchRiskQueue();

    final high = risks.where((r) => r.band.toLowerCase() == 'high').length;

    final medium = risks.where((r) => r.band.toLowerCase() == 'medium').length;

    final low = risks.where((r) => r.band.toLowerCase() == 'low').length;

    return (high: high, medium: medium, low: low);
  }

  void _openRiskQueue(BuildContext context, String band) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RiskQueuePage(riskBand: band)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({int high, int medium, int low})>(
      future: _future,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(context, 'failedRisk'),
                    style: const TextStyle(color: AppColors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AuthService.friendlyError(snapshot.error!),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _future = _loadRisk();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // No Data
        if (!snapshot.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr(context, 'noRisk')),
            ),
          );
        }

        final data = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _RiskRow(
                  title: tr(context, 'highRisk'),
                  value: '${data.high} ${tr(context, 'assetsCount')}',
                  icon: Icons.warning_amber_outlined,
                  onTap: () {
                    _openRiskQueue(context, 'high');
                  },
                ),

                const Divider(),
                _RiskRow(
                  title: tr(context, 'medRisk'),
                  value: '${data.medium} ${tr(context, 'assetsCount')}',
                  icon: Icons.error_outline,
                  onTap: () {
                    _openRiskQueue(context, 'medium');
                  },
                ),

                const Divider(),
                _RiskRow(
                  title: tr(context, 'lowRisk'),
                  value: '${data.low} ${tr(context, 'assetsCount')}',
                  icon: Icons.check_circle_outline,
                  onTap: () {
                    _openRiskQueue(context, 'low');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _RiskRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 26),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(width: 8),

            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
