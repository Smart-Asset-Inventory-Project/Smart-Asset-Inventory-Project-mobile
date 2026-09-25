import 'package:flutter/material.dart';
import '../../core/services/ai_prediction_service.dart';
import '../../core/services/asset_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ai_prediction_model.dart';
import '../../models/asset_model.dart';
import '../custody/request_transfer_page.dart';
import '../maintenance/create_work_order_page.dart';
import '../procurement/procurement_page.dart';
import 'retire_asset_page.dart';
import 'edit_asset_page.dart';
import '../../core/l10n/strings.dart';
import '../../core/widgets/role_gate.dart';

/// AST-FR-02/03/04/10: تفاصيل الأصل. المتقاعد read-only ولا يقبل نقل/صيانة.
class AssetDetailPage extends StatefulWidget {
  final String assetId;
  const AssetDetailPage({super.key, required this.assetId});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  late Future<AssetModel> _future;

  @override
  void initState() {
    super.initState();
    _future = AssetService().fetchAssetDetail(widget.assetId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'assetDetail'))),
      body: FutureBuilder<AssetModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final a = snap.data!;
          final retired =
              a.status.toLowerCase() == 'retired';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (retired)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tr(context, 'retired'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(a.tag,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('${a.brand ?? ''} ${a.model ?? ''}',
                          style: const TextStyle(
                              fontSize: 15, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                // Card: الأساسيات
                _sectionCard(context, tr(context, 'overview'), [
                  _row(tr(context, 'serial'), a.serial ?? '-'),
                  _row(tr(context, 'category'), tr(context, a.category)),
                  _row(tr(context, 'status'), tr(context, a.status)),
                  _row(tr(context, 'condition'), tr(context, a.condition)),
                ]),
                
                const SizedBox(height: 16),
                
                // Card: الموقع والمسؤولية (أسماء الباك اند بدل UUID)
                _sectionCard(context, tr(context, 'location'), [
                  _row(tr(context, 'location'),
                      a.locationName ?? a.locationId),
                  _row(tr(context, 'custodian'),
                      a.custodianName ?? a.custodianId ?? '-'),
                ]),
                
                const SizedBox(height: 16),

                // Card: البيانات المالية
                _sectionCard(context, tr(context, 'assetValue'), [
                  _row(tr(context, 'purchaseCost'),
                      a.purchaseCost?.toString() ?? '-'),
                  _row(tr(context, 'purchaseDate'), a.purchaseDate ?? '-'),
                ]),

                const SizedBox(height: 16),

                // Card: سجل الأصل (نقل/عهدة/صيانة) — GET /assets/{id}/history
                _sectionCard(context, 'History', [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: AssetService().fetchAssetHistory(widget.assetId),
                    builder: (context, hsnap) {
                      if (hsnap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                        );
                      }
                      final events = hsnap.data ?? [];
                      if (events.isEmpty) {
                        return const Text('-',
                            style: TextStyle(color: Colors.grey));
                      }
                      return Column(
                        children: events.take(10).map((e) {
                          final at = (e['at'] ?? '').toString();
                          final day = at.length >= 10 ? at.substring(0, 10) : at;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.history_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${e['type'] ?? ''} • ${e['action'] ?? ''} • $day',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 16),

                // Card: توقع الصيانة بالذكاء الاصطناعي (عند الطلب فقط)
                _AiPredictionCard(asset: a),

                const SizedBox(height: 32),
                HideForAuditor(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.swap_horiz),
                          label: Text(tr(context, 'transfer')),
                          onPressed: retired
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RequestTransferPage(
                                          presetAssetId: a.id),
                                    ),
                                  );
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.build_outlined),
                          label: Text(tr(context, 'workOrder')),
                          onPressed: retired
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateWorkOrderPage(
                                        presetAssetId: a.id,
                                        presetAssetTag: a.tag,
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(tr(context, 'procurementTitle')),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProcurementPage(assetId: a.id),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HideForAuditor(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.archive_outlined),
                          label: Text(tr(context, 'retire')),
                          onPressed: retired
                              ? null
                              : () async {
                                  final ok = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RetireAssetPage(
                                        assetId: a.id,
                                        assetTag: a.tag,
                                      ),
                                    ),
                                  );
                                  if (ok == true && context.mounted) {
                                    setState(() {
                                      _future = AssetService()
                                          .fetchAssetDetail(widget.assetId);
                                    });
                                  }
                                },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                HideForAuditor(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(tr(context, 'edit')),
                        onPressed: retired
                            ? null
                            : () async {
                                final ok = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditAssetPage(asset: a),
                                  ),
                                );
                                if (ok == true && context.mounted) {
                                  setState(() {
                                    _future = AssetService()
                                        .fetchAssetDetail(widget.assetId);
                                  });
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        label: Text(tr(context, 'delete'),
                            style:
                                const TextStyle(color: Colors.red)),
                        onPressed: retired
                            ? null
                            : () => _confirmDelete(context, a),
                      ),
                    ),
                  ],
                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AssetModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'delete')),
        content: Text(tr(context, 'confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
                MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(context, 'delete'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await AssetService().deleteAsset(a.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'deleted'))),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _sectionCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue.withValues(alpha: 0.8))),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

/// AI failure-risk prediction for one asset — on demand only.
/// Shows loading, validation (missing asset fields / 422 details) and
/// network-error states, then level + score + probability + inputs used.
class _AiPredictionCard extends StatefulWidget {
  final AssetModel asset;
  const _AiPredictionCard({required this.asset});

  @override
  State<_AiPredictionCard> createState() => _AiPredictionCardState();
}

class _AiPredictionCardState extends State<_AiPredictionCard> {
  Future<({AiPredictRequest req, AiPredictResult res, bool costRecords})>?
      _future;

  void _run() => setState(() {
        _future =
            AiPredictionService().predictForAsset(widget.asset);
      });

  Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'LOW':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
      case 'CRITICAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('AI Prediction',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue.withValues(alpha: 0.8))),
                const Spacer(),
                if (_future != null)
                  TextButton(
                    onPressed: _run,
                    child: const Text('Re-run'),
                  ),
              ],
            ),
            const Divider(height: 24),
            if (_future == null)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.psychology_outlined, size: 20),
                  label: const Text('Predict failure risk'),
                  onPressed: _run,
                ),
              )
            else
              FutureBuilder<
                  ({
                    AiPredictRequest req,
                    AiPredictResult res,
                    bool costRecords
                  })>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    final err = snap.error;
                    final details = err is AiRequestException
                        ? err.details
                        : const <String>[];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          err is AiRequestException
                              ? err.message
                              : err.toString().replaceFirst('Exception: ', ''),
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                        ...details.map((d) => Padding(
                              padding:
                                  const EdgeInsets.only(top: 4),
                              child: Text('• $d',
                                  style: const TextStyle(fontSize: 12)),
                            )),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _run,
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }
                  final r = snap.data!.res;
                  final q = snap.data!.req;
                  final color = _levelColor(r.riskLevel);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r.riskLevel.isEmpty ? '-' : r.riskLevel,
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Score ${r.riskScore.toStringAsFixed(1)} / 100 • '
                              'Failure ${r.probabilityPercent.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (r.failurePredicted)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Failure predicted',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      if (r.isAiFallback)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Fallback model used',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 12)),
                        ),
                      if (r.reasons.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...r.reasons.map((e) => Padding(
                              padding:
                                  const EdgeInsets.only(top: 2),
                              child: Text('• $e',
                                  style: const TextStyle(fontSize: 12)),
                            )),
                      ],
                      const Divider(height: 24),
                      Text(
                        'Inputs: age ${q.assetAgeMonths}m / life ${q.expectedLifetimeMonths}m / '
                        '${q.condition} / maintenance ${q.maintenanceCount} '
                        '(90d: ${q.recentMaintenanceCount90d}) / '
                        'downtime ${q.downtimeHours90d}h / cost ${q.repairCost90d}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (!snap.data!.costRecords)
                        Text(
                          'No service-event cost records — 90d sums are 0 from work orders alone.',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      if (r.modelVersion.isNotEmpty)
                        Text(
                          'Model: ${r.modelVersion}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
