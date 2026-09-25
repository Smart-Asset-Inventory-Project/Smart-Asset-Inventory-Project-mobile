import 'package:flutter/material.dart';
import '../../core/services/procurement_service.dart';
import '../../models/procurement_model.dart';

/// Warranties expiring within [days] — GET /warranties/expiring?days=N.
class ExpiringWarrantiesPage extends StatefulWidget {
  const ExpiringWarrantiesPage({super.key});

  @override
  State<ExpiringWarrantiesPage> createState() => _ExpiringWarrantiesPageState();
}

class _ExpiringWarrantiesPageState extends State<ExpiringWarrantiesPage> {
  int _days = 30;
  late Future<List<WarrantyInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProcurementService().fetchExpiringWarranties(days: _days);
  }

  void _reload() => setState(() {
        _future = ProcurementService().fetchExpiringWarranties(days: _days);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warranties expiring')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [30, 60, 90]
                  .map((d) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${d}d'),
                          selected: _days == d,
                          onSelected: (_) {
                            _days = d;
                            _reload();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<WarrantyInfo>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Center(
                      child: Text('No expiring warranties in $_days days'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final w = items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: ListTile(
                        leading: const Icon(Icons.verified_outlined),
                        title: Text(w.provider ?? '-',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${w.assetId} • ${w.startDate ?? '-'} → ${w.endDate ?? '-'}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
