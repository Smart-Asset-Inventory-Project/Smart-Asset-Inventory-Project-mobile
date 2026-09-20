import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import '../../core/widgets/qr_scanner_widget.dart';
import '../../models/asset_model.dart';

/// AST-FR-07: جلسة جرد مبسطة.
/// يمسح Tag ويقارن الموقع المتوقع بالمرصود ويعرض discrepancy.
class StocktakePage extends StatefulWidget {
  const StocktakePage({super.key});

  @override
  State<StocktakePage> createState() => _StocktakePageState();
}

class _StocktakePageState extends State<StocktakePage> {
  final List<Map<String, String>> _obs = [];
  String _currentLocation = 'loc-b1-r101';
  late final TextEditingController _locCtrl;

  @override
  void initState() {
    super.initState();
    _locCtrl = TextEditingController(text: _currentLocation);
  }

  @override
  void dispose() {
    _locCtrl.dispose();
    super.dispose();
  }

  void _onScanned(String tag) async {
    try {
      final assets = await AssetService().fetchAssets(query: tag);
      final AssetModel? found =
          assets.isNotEmpty ? assets.first : null;
      final state = found == null
          ? 'unexpected'
          : (found.locationId == _currentLocation ? 'verified' : 'moved');
      setState(() {
        _obs.add({'tag': tag, 'state': state});
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = _obs.where((e) => e['state'] == 'verified').length;
    final moved = _obs.where((e) => e['state'] == 'moved').length;
    final unexpected = _obs.where((e) => e['state'] == 'unexpected').length;
    return Scaffold(
      appBar: AppBar(title: const Text('Stocktake (QR)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Current location ID',
              border: OutlineInputBorder(),
            ),
            controller: _locCtrl,
            onChanged: (v) => _currentLocation = v.trim(),
          ),
          const SizedBox(height: 12),
          QrScannerWidget(onScanned: _onScanned),
          const SizedBox(height: 12),
          Text('Verified: $verified • Moved: $moved • Unexpected: $unexpected',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          ..._obs.map((e) => ListTile(
                leading: Icon(
                  e['state'] == 'verified'
                      ? Icons.check_circle
                      : Icons.warning,
                  color: e['state'] == 'verified'
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text(e['tag']!),
                trailing: Chip(label: Text(e['state']!)),
              )),
        ],
      ),
    );
  }
}
