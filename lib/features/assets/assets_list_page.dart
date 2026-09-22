import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import '../../core/services/catalog_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/role_gate.dart';
import '../../models/asset_model.dart';
import 'add_asset_page.dart';
import 'asset_detail_page.dart';
import 'import_assets_page.dart';
import '../../core/l10n/strings.dart';

/// AST-FR-01/02: بحث وعرض الأصول بكل مستوى + فلتر فئة.
/// الفئات من /categories الحقيقية، وبديل محلي عند غياب السيرفر.
class AssetsListPage extends StatefulWidget {
  final String? locationId;
  final String? locationName;

  /// فلتر فئة مبدئي (من قسم byCategory في الداشبورد).
  final String? initialCategory;

  /// نطاق الكاستوديان (scopeLocationId): يفلتر الأصول بالنطاق.
  final String? scopeLocationId;
  const AssetsListPage(
      {super.key,
      this.locationId,
      this.locationName,
      this.initialCategory,
      this.scopeLocationId});

  @override
  State<AssetsListPage> createState() => _AssetsListPageState();
}

class _AssetsListPageState extends State<AssetsListPage> {
  final _service = AssetService();
  final _search = TextEditingController();
  late String _category;
  List<String> _categories = const [
    'computer',
    'screen',
    'furniture',
    'printer',
    'lab'
  ];
  late Future<List<AssetModel>> _future;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'all';
    _reload(initial: true);
    CatalogService().fetchCategories().then((cats) {
      if (!mounted || cats.isEmpty) return;
      setState(() {
        _categories = cats.map((c) => c.name).toList();
      });
    }).catchError((_) {});
  }

  void _reload({bool initial = false}) {
    final f = _service.fetchAssets(
      query: _search.text.trim().isEmpty ? null : _search.text.trim(),
      category: _category == 'all' ? null : _category,
      locationId: widget.locationId,
      scopeLocationId: widget.scopeLocationId,
    );
    if (initial) {
      _future = f;
    } else {
      // أقواس عادية: الـ arrow كانت ترجع Future وتكسر setState
      setState(() {
        _future = f;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'computer':
        return Icons.computer_outlined;
      case 'screen':
        return Icons.monitor_outlined;
      case 'furniture':
        return Icons.chair_outlined;
      case 'printer':
        return Icons.print_outlined;
      case 'lab':
        return Icons.science_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.green;
      case 'in_maintenance':
        return AppColors.orange;
      case 'retired':
        return AppColors.grey;
      default:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.locationName == null
              ? tr(context, 'assets')
              : '${tr(context, 'assets')} • ${widget.locationName}'),
          actions: [
            HideForAuditor(
              child: IconButton(
                tooltip: 'Import CSV',
                icon: const Icon(Icons.upload_file_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ImportAssetsPage()),
                  );
                  _reload();
                },
              ),
            ),
          ]),
      floatingActionButton: HideForAuditor(
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: Text(tr(context, 'add')),
          onPressed: () async {
            final ok = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAssetPage()),
            );
            if (ok == true) _reload();
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                hintText: tr(context, 'searchHint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _reload();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // فلتر الفئة من /categories: Wrap يعرض كل الشيبس بدون سكرول
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ['all', ..._categories]
                  .map((c) => ChoiceChip(
                        label: Text(c == 'all' ? tr(context, 'all') : c),
                        selected: _category == c,
                        onSelected: (_) {
                          _category = c;
                          _reload();
                        },
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<AssetModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${snap.error}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('No assets found'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final a = items[i];
                    final sColor = _statusColor(a.status);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_catIcon(a.category), color: AppColors.blue),
                        ),
                        title: Text(a.tag,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${tr(context, a.category)} • ${a.locationId}',
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: sColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tr(context, a.status),
                                style: TextStyle(
                                    color: sColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right_outlined, size: 20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssetDetailPage(assetId: a.id),
                          ),
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
    );
  }
}
