import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import '../../core/theme/app_colors.dart';
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
