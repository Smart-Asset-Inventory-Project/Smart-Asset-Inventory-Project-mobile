import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import '../../models/asset_model.dart';
import '../custody/request_transfer_page.dart';
import '../maintenance/work_orders_page.dart';
import '../procurement/procurement_page.dart';
import 'retire_asset_page.dart';

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
      appBar: AppBar(title: const Text('Asset Detail')),
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
                    child: const Text(
                      'RETIRED — read-only, stays in audit reports (AST-FR-10)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2_outlined, size: 96),
                      const SizedBox(height: 8),
                      Text(a.tag,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${a.brand ?? ''} ${a.model ?? ''}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _row('Serial', a.serial ?? '-'),
                _row('Category', a.category),
                _row('Condition', a.condition),
                _row('Status', a.status),
                _row('Location', a.locationId),
                _row('Custodian', a.custodianId ?? '-'),
                _row('Purchase cost', a.purchaseCost?.toString() ?? '-'),
                _row('Purchase date', a.purchaseDate ?? '-'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Transfer'),
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
                        label: const Text('Work order'),
                        onPressed: retired
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const WorkOrdersPage()),
                                );
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Procurement'),
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
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Retire'),
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
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 130,
              child: Text(k, style: const TextStyle(color: Colors.grey))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
