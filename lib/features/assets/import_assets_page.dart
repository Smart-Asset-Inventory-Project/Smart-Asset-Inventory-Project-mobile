import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import '../../core/services/catalog_service.dart';
import '../../core/services/location_service.dart';

/// AST-FR-02: استيراد CSV بتقرير نجاح/أخطاء لكل صف.
/// الأعمدة: assetTag,name,category,location,serialNumber,model,condition,purchaseCost
/// الفئة والموقع بالاسم ويتحلوا لـ IDs من الباك اند.
class ImportAssetsPage extends StatefulWidget {
  const ImportAssetsPage({super.key});

  @override
  State<ImportAssetsPage> createState() => _ImportAssetsPageState();
}

class _ImportResult {
  int success = 0;
  final List<String> errors = [];
}

class _ImportAssetsPageState extends State<ImportAssetsPage> {
  final _csv = TextEditingController();
  bool _loading = false;
  _ImportResult? _report;

  static const _sample = '''assetTag,name,category,location,serialNumber,model,condition,purchaseCost
AST-9001,Dell Laptop,Server,Room 5,SN-9001,Latitude,GOOD,1200
AST-9002,HP Printer,Chair,Room 5,SN-9002,LaserJet,FAIR,400''';

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  List<String> _splitRow(String line) {
    // CSV بسيط بدون quotes متداخلة (كافي لسيناريو القبول).
    return line.split(',').map((e) => e.trim()).toList();
  }

  Future<void> _import() async {
    final text = _csv.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _report = null;
    });
    final report = _ImportResult();
    try {
      final cats = await CatalogService().fetchCategories();
      final locs = await LocationService().fetchLocations();
      final catByName = {for (final c in cats) c.name.toLowerCase(): c.id};
      final locByName = {for (final l in locs) l.name.toLowerCase(): l.id};
      final lines =
          text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (lines.isEmpty) return;
      final header = _splitRow(lines.first)
          .map((e) => e.toLowerCase())
          .toList();
      const required = ['assettag', 'name', 'category', 'location'];
      for (final r in required) {
        if (!header.contains(r)) {
          report.errors.add('Missing column: $r');
        }
      }
      if (report.errors.isNotEmpty) {
        setState(() => _report = report);
        return;
      }
      final idx = {for (var i = 0; i < header.length; i++) header[i]: i};
      String col(List<String> row, String name) {
        final i = idx[name]!;
        return i < row.length ? row[i] : '';
      }

      for (var r = 1; r < lines.length; r++) {
        final row = _splitRow(lines[r]);
        final tag = col(row, 'assettag');
        final name = col(row, 'name');
        final catName = col(row, 'category').toLowerCase();
        final locName = col(row, 'location').toLowerCase();
        if (tag.isEmpty || name.isEmpty) {
          report.errors.add('Row ${r + 1}: assetTag and name are required');
          continue;
        }
        final catId = catByName[catName];
        if (catId == null) {
          report.errors.add('Row ${r + 1}: unknown category "${col(row, 'category')}"');
          continue;
        }
        final locId = locByName[locName];
        if (locId == null) {
          report.errors.add('Row ${r + 1}: unknown location "${col(row, 'location')}"');
          continue;
        }
        try {
          await AssetService().createAsset({
            'assetTag': tag,
            'name': name,
            'categoryId': catId,
            'locationId': locId,
            'serialNumber':
                col(row, 'serialnumber').isEmpty ? null : col(row, 'serialnumber'),
            'model': col(row, 'model').isEmpty ? null : col(row, 'model'),
            'condition':
                col(row, 'condition').isEmpty ? 'GOOD' : col(row, 'condition'),
            'purchaseCost': double.tryParse(col(row, 'purchasecost')),
          });
          report.success++;
        } catch (e) {
          report.errors.add(
              'Row ${r + 1} ($tag): ${e.toString().replaceFirst('Exception: ', '')}');
        }
        if (mounted) setState(() => _report = report);
      }
    } catch (e) {
      report.errors
          .add(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _report = report;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Assets (CSV)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Columns: assetTag,name,category,location,serialNumber,model,condition,purchaseCost',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _csv,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Paste CSV here...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _csv.text = _sample),
                child: const Text('Load sample'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_outlined),
                label: Text(_loading ? '...' : 'Import'),
                onPressed: _loading ? null : _import,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          if (_report != null) ...[
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading:
                    const Icon(Icons.check_circle, color: Colors.green),
                title: Text('${_report!.success} imported'),
              ),
            ),
            if (_report!.errors.isNotEmpty)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_report!.errors.length} errors',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      const SizedBox(height: 8),
                      ..._report!.errors.map((e) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: Text(e,
                                style: const TextStyle(fontSize: 13)),
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
