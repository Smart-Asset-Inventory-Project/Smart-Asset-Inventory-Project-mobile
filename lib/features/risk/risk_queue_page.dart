// import 'package:flutter/material.dart';
// import '../../core/services/insights_service.dart';
// import '../../models/work_order_model.dart';
//
// /// AST-FR-09: طابور المخاطر للعرض فقط مع الأسباب.
// /// لا يغير state أصل أو أمر شغل؛ يتطلب تأكيد بشري في الباك اند.
// class RiskQueuePage extends StatefulWidget {
//   const RiskQueuePage({super.key});
//
//   @override
//   State<RiskQueuePage> createState() => _RiskQueuePageState();
// }
//
// class _RiskQueuePageState extends State<RiskQueuePage> {
//   late Future<List<RiskItemModel>> _future;
//
//   @override
//   void initState() {
//     super.initState();
//     _future = InsightsService().fetchRiskQueue();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Maintenance Risk Queue')),
//       body: FutureBuilder<List<RiskItemModel>>(
//         future: _future,
//         builder: (context, snap) {
//           if (snap.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snap.hasError) {
//             return Center(child: Text('Error: ${snap.error}'));
//           }
//           final items = snap.data ?? [];
//           if (items.isEmpty) return const Center(child: Text('No risks'));
//           return ListView.separated(
//             itemCount: items.length,
//             separatorBuilder: (_, __) => const Divider(height: 1),
//             itemBuilder: (context, i) {
//               final r = items[i];
//               final color = r.band == 'high'
//                   ? Colors.red
//                   : r.band == 'medium'
//                       ? Colors.orange
//                       : Colors.green;
//               return ListTile(
//                 leading: Icon(Icons.warning, color: color),
//                 title: Text('${r.assetTag} • ${r.band}',
//                     style: const TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: Text(
//                     'score ${r.score.toStringAsFixed(2)}\n${r.reasons.join(' • ')}'),
//                 isThreeLine: true,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }








import 'package:flutter/material.dart';

import '../../core/services/insights_service.dart';
import '../../models/work_order_model.dart';

/// AST-FR-09:
/// طابور المخاطر للعرض فقط مع الأسباب.
/// لا يغير state أصل أو أمر شغل؛
/// يتطلب تأكيد بشري في الباك اند.
class RiskQueuePage extends StatefulWidget {
  final String? riskBand;

  const RiskQueuePage({
    super.key,
    this.riskBand,
  });

  @override
  State<RiskQueuePage> createState() =>
      _RiskQueuePageState();
}

class _RiskQueuePageState extends State<RiskQueuePage> {
  late Future<List<RiskItemModel>> _future;

  @override
  void initState() {
    super.initState();

    _future = _loadRisks();
  }

  // =====================================================
  // Load Risks
  // =====================================================

  Future<List<RiskItemModel>> _loadRisks() async {
    final items =
    await InsightsService().fetchRiskQueue();

    // لو مفيش Filter
    // نعرض كل الـ risks
    if (widget.riskBand == null) {
      return items;
    }

    // Filter حسب نوع الـ Risk
    return items.where((item) {
      return item.band.toLowerCase() ==
          widget.riskBand!.toLowerCase();
    }).toList();
  }

  // =====================================================
  // Page Title
  // =====================================================

  String get _pageTitle {
    switch (widget.riskBand?.toLowerCase()) {
      case 'high':
        return 'High Risk';

      case 'medium':
        return 'Medium Risk';

      case 'low':
        return 'Low Risk';

      default:
        return 'Maintenance Risk Queue';
    }
  }

  // =====================================================
  // Risk Color
  // =====================================================

  Color _getRiskColor(String band) {
    switch (band.toLowerCase()) {
      case 'high':
        return Colors.red;

      case 'medium':
        return Colors.orange;

      case 'low':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  // =====================================================
  // Risk Icon
  // =====================================================

  IconData _getRiskIcon(String band) {
    switch (band.toLowerCase()) {
      case 'high':
        return Icons.warning_amber_outlined;

      case 'medium':
        return Icons.error_outline;

      case 'low':
        return Icons.check_circle_outline;

      default:
        return Icons.warning;
    }
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: FutureBuilder<List<RiskItemModel>>(
        future: _future,

        builder: (context, snapshot) {
          // =========================
          // Loading
          // =========================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // =========================
          // Error
          // =========================

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          // =========================
          // Data
          // =========================

          final items = snapshot.data ?? [];

          // =========================
          // Empty
          // =========================

          if (items.isEmpty) {
            return Center(
              child: Text(
                widget.riskBand == null
                    ? 'No risks'
                    : 'No ${widget.riskBand} risks',
              ),
            );
          }

          // =========================
          // Risk List
          // =========================

          return ListView.separated(
            itemCount: items.length,

            separatorBuilder: (_, __) =>
            const Divider(
              height: 1,
            ),

            itemBuilder: (context, index) {
              final r = items[index];

              final color =
              _getRiskColor(r.band);

              final icon =
              _getRiskIcon(r.band);

              return ListTile(
                leading: Icon(
                  icon,
                  color: color,
                ),

                title: Text(
                  '${r.assetTag} • ${r.band.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  'score ${r.score.toStringAsFixed(2)}\n'
                      '${r.reasons.join(' • ')}',
                ),

                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
