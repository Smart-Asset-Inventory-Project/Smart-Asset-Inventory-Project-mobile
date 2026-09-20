import 'package:flutter/material.dart';
import 'package:smart_asset_inventory/core/theme/app_colors.dart';

import '../../core/services/insights_service.dart';
import '../risk/risk_queue_page.dart';

class DashboardRiskSection extends StatefulWidget {
  const DashboardRiskSection({super.key});

  @override
  State<DashboardRiskSection> createState() =>
      _DashboardRiskSectionState();
}

class _DashboardRiskSectionState
    extends State<DashboardRiskSection> {
  late Future<({int high, int medium, int low})> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadRisk();
  }

  Future<({int high, int medium, int low})> _loadRisk() async {
    final risks = await InsightsService().fetchRiskQueue();

    final high = risks
        .where(
          (r) => r.band.toLowerCase() == 'high',
    )
        .length;

    final medium = risks
        .where(
          (r) => r.band.toLowerCase() == 'medium',
    )
        .length;

    final low = risks
        .where(
          (r) => r.band.toLowerCase() == 'low',
    )
        .length;

    return (
    high: high,
    medium: medium,
    low: low,
    );
  }

  // =========================
  // Open Risk Queue
  // =========================

  void _openRiskQueue(
      BuildContext context,
      String band,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiskQueuePage(
          riskBand: band,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        ({int high, int medium, int low})>(
      future: _future,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Failed to load maintenance risk',
                style: TextStyle(
                  color: AppColors.red,
                ),
              ),
            ),
          );
        }

        // No Data
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No risk data available',
              ),
            ),
          );
        }

        final data = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // =========================
                // High Risk
                // =========================

                _RiskRow(
                  title: 'High Risk',
                  value: '${data.high} Assets',
                  icon: Icons.warning_amber_outlined,
                  onTap: () {
                    _openRiskQueue(
                      context,
                      'high',
                    );
                  },
                ),

                const Divider(),

                // =========================
                // Medium Risk
                // =========================

                _RiskRow(
                  title: 'Medium Risk',
                  value: '${data.medium} Assets',
                  icon: Icons.error_outline,
                  onTap: () {
                    _openRiskQueue(
                      context,
                      'medium',
                    );
                  },
                ),

                const Divider(),

                // =========================
                // Low Risk
                // =========================

                _RiskRow(
                  title: 'Low Risk',
                  value: '${data.low} Assets',
                  icon: Icons.check_circle_outline,
                  onTap: () {
                    _openRiskQueue(
                      context,
                      'low',
                    );
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

// =====================================================
// Risk Row
// =====================================================

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
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 26,
            ),

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

            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}