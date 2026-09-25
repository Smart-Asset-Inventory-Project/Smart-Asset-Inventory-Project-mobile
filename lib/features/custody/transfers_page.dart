import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/location_service.dart';
import '../../core/services/transfer_outbox.dart';
import '../../core/services/transfer_service.dart';
import '../../core/services/user_directory.dart';
import '../../core/widgets/role_gate.dart';
import '../../models/transfer_model.dart';
import 'request_transfer_page.dart';

/// AST-FR-04: سجل النقل + تسجيل نقل جديد.
/// الباك اند يسجل النقل فوريا (completed) بلا اعتماد.
class TransfersPage extends StatefulWidget {
  /// Scope-Based: الكاستوديان يرى نقل نطاقه فقط.
  final String? scopeLocationId;

  /// Deep link from dashboard cards: 'pending' shows pending only.
  final String? initialStatus;
  const TransfersPage({super.key, this.scopeLocationId, this.initialStatus});

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  late Future<(List<TransferModel>, Map<String, String>)> _future;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus ?? 'all';
    _future = _load();
  }

  Future<(List<TransferModel>, Map<String, String>)> _load() async {
    // Parallel: transfers + locations in one round.
    final backend = await TransferService().fetchTransfers(
      scopeLocationId: widget.scopeLocationId,
      status: _status == 'all' ? null : _status,
    );
    // Device-kept requests (backend refused them): always pending.
    final outbox = await TransferOutbox.load();
    final local = outbox
        .map((o) => TransferModel(
              id: o.id,
              assetId: o.assetId,
              assetTag: o.assetId,
              fromLocation: '-',
              toLocation: o.toLocationId,
              status: 'pending',
              requestedBy: 'this device',
              requestedAt: o.createdAt,
              reason: o.reason,
            ))
        .toList();
    var items = <TransferModel>[...local, ...backend];
    if (_status != 'all') {
      items = items.where((t) => t.status == _status).toList();
    }
    var locNames = <String, String>{};
    // Locations best-effort in parallel with nothing else pending;
    // fetchLocations is already fast single call.
    try {
      final locs = await LocationService().fetchLocations();
      locNames = {for (final l in locs) l.id: l.name};
    } catch (_) {}
    return (items, locNames);
  }

  bool _isLocal(TransferModel t) => t.id.startsWith('local-');

  Future<void> _retryLocal(TransferModel t) async {
    final entries = await TransferOutbox.load();
    final match = entries.where((e) => e.id == t.id).toList();
    if (match.isEmpty) return;
    final o = match.first;
    try {
      await TransferService().requestTransfer(
        assetId: o.assetId,
        toLocation: o.toLocationId,
        reason: o.reason,
      );
      await TransferOutbox.remove(o.id);
      if (!mounted) return;
      setState(() {
        _status = 'all';
        _future = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _discardLocal(TransferModel t) async {
    await TransferOutbox.remove(t.id);
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

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
            // Backend completes transfers immediately (no pending state),
            // so a sent request is hidden under the Pending filter —
            // jump back to All so the user sees it. A device-kept
            // request ('local') lands on Pending instead.
            if (ok == 'local') {
              setState(() {
                _status = 'pending';
                _future = _load();
              });
            } else if (ok == true) {
              setState(() {
                _status = 'all';
                _future = _load();
              });
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: ['all', 'pending', 'completed']
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(tr(context, s)),
                              selected: _status == s,
                              onSelected: (_) {
                                setState(() {
                                  _status = s;
                                  _future = _load();
                                });
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              Expanded(
                child: FutureBuilder<(List<TransferModel>, Map<String, String>)>(
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
                          // Device-kept request: not on the server yet.
                          if (_isLocal(t)) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'On this device • not sent (no permission)',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _discardLocal(t),
                                  child: const Text('Discard',
                                      style:
                                          TextStyle(color: Colors.grey)),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.send_outlined,
                                      size: 16),
                                  label: const Text('Retry send'),
                                  onPressed: () => _retryLocal(t),
                                ),
                              ],
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
