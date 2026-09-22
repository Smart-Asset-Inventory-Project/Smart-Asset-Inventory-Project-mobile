import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/location_service.dart';
import '../../core/services/transfer_service.dart';
import '../../core/services/user_directory.dart';
import '../../core/widgets/role_gate.dart';
import '../../models/transfer_model.dart';
import 'request_transfer_page.dart';

/// AST-FR-04: سجل النقل + تسجيل نقل جديد.
/// الباك اند يسجل النقل فوريا (completed) بلا اعتماد.
class TransfersPage extends StatefulWidget {
  const TransfersPage({super.key});

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  late Future<(List<TransferModel>, Map<String, String>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<TransferModel>, Map<String, String>)> _load() async {
    final items = await TransferService().fetchTransfers();
    var locNames = <String, String>{};
    try {
      final locs = await LocationService().fetchLocations();
      locNames = {for (final l in locs) l.id: l.name};
    } catch (_) {}
    return (items, locNames);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'custodyTransfers'))),
      floatingActionButton: HideForAuditor(
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: Text(tr(context, 'request')),
          onPressed: () async {
            final ok = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequestTransferPage()),
            );
            if (ok == true) _reload();
          },
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<(List<TransferModel>, Map<String, String>)>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('${tr(context, 'required')}: ${snap.error}'));
              }
              final items = snap.data?.$1 ?? [];
              final locNames = snap.data?.$2 ?? {};
              String locName(String id) => locNames[id] ?? id;
              if (items.isEmpty) return Center(child: Text(tr(context, 'noTransfers')));
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = items[i];
                  // الباك اند يسجل النقل فوريا: completed. pending يظهر
                  // فقط مع mock محلي.
                  final color = t.status == 'completed'
                      ? Colors.green
                      : t.status == 'approved'
                          ? Colors.green
                          : t.status == 'rejected'
                              ? Colors.red
                              : Colors.orange;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.swap_horiz, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.assetTag,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${locName(t.fromLocation)}  ➔  ${locName(t.toLocation)}',
                                      style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  tr(context, t.status),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: color.withValues(alpha: 0.12),
                                side: BorderSide.none,
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${tr(context, 'by')} ${UserDirectory.instance.name(t.requestedBy)} • ${t.requestedAt.length >= 10 ? t.requestedAt.substring(0, 10) : t.requestedAt}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (t.decidedBy != null)
                                Text(
                                  '✓ ${t.decidedBy}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: color),
                                ),
                            ],
                          ),
                          if (t.reason != null && t.reason!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              t.reason!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
