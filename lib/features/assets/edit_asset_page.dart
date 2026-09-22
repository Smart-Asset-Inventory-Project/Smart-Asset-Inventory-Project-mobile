import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import '../../core/services/catalog_service.dart';
import '../../core/services/location_service.dart';
import '../../core/l10n/strings.dart';
import '../../models/asset_model.dart';
import '../../models/category_model.dart';

/// تعديل أصل عبر PUT /assets/:id. المتقاعد لا يفتح هذه الشاشة أصلا.
class EditAssetPage extends StatefulWidget {
  final AssetModel asset;
  const EditAssetPage({super.key, required this.asset});

  @override
  State<EditAssetPage> createState() => _EditAssetPageState();
}

class _EditAssetPageState extends State<EditAssetPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tag;
  late final TextEditingController _name;
  late final TextEditingController _serial;
  late final TextEditingController _model;
  late final TextEditingController _cost;
  List<CategoryModel> _categories = [];
  List<LocationModel> _locations = [];
  String? _categoryId;
  String? _locationId;
  late String _condition;
  late String _status;
  bool _loading = false;
  bool _loadingLists = true;

  static const _conditions = ['GOOD', 'FAIR', 'POOR', 'DAMAGED'];

  /// RETIRED ممنوعة هنا عمدا: التقاعد يتم عبر POST /retirements
  /// بسجل سبب واعتماد (RetireAssetPage) وليس بالتعديل المباشر.
  static const _statuses = ['ACTIVE', 'MAINTENANCE', 'LOST'];

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _tag = TextEditingController(text: a.tag);
    _name = TextEditingController(text: a.name ?? '');
    _serial = TextEditingController(text: a.serial ?? '');
    _model = TextEditingController(text: a.model ?? '');
    _cost = TextEditingController(
        text: a.purchaseCost == null ? '' : a.purchaseCost.toString());
    _categoryId = a.categoryId;
    _locationId = a.locationId;
    _condition = a.condition.toUpperCase();
    if (!_conditions.contains(_condition)) _condition = 'GOOD';
    _status = a.status.toUpperCase();
    // المتقاعد لا يفتح الشاشة أصلا؛ أي حالة غير مدعومة ترجع ACTIVE.
    if (!_statuses.contains(_status)) _status = 'ACTIVE';
    _loadLists();
  }

  Future<void> _loadLists() async {
    try {
      final cats = await CatalogService().fetchCategories();
      final locs = await LocationService().fetchLocations();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _locations = locs;
        if (_categoryId == null && cats.isNotEmpty) {
          _categoryId = cats.first.id;
        }
        _loadingLists = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLists = false);
    }
  }

  @override
  void dispose() {
    _tag.dispose();
    _name.dispose();
    _serial.dispose();
    _model.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AssetService().updateAsset(widget.asset.id, {
        'assetTag': _tag.text.trim(),
        'name': _name.text.trim(),
        'serialNumber':
            _serial.text.trim().isEmpty ? null : _serial.text.trim(),
        if (_categoryId != null) 'categoryId': _categoryId,
        if (_locationId != null) 'locationId': _locationId,
        'model': _model.text.trim().isEmpty ? null : _model.text.trim(),
        'condition': _condition,
        'status': _status,
        'purchaseCost': double.tryParse(_cost.text.trim()),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${tr(context, 'assetDetail')} • ${tr(context, 'edit')}')),
      body: _loadingLists
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _tag,
                    decoration: const InputDecoration(
                        labelText: 'assetTag *',
                        border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? tr(context, 'required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                        labelText: 'name *',
                        border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? tr(context, 'required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _serial,
                    decoration: InputDecoration(
                        labelText: tr(context, 'serial'),
                        border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: InputDecoration(
                        labelText: tr(context, 'category'),
                        border: const OutlineInputBorder()),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _locations.any((l) => l.id == _locationId)
                        ? _locationId
                        : null,
                    decoration: InputDecoration(
                        labelText: tr(context, 'location'),
                        border: const OutlineInputBorder()),
                    items: _locations
                        .map((l) => DropdownMenuItem(
                            value: l.id,
                            child: Text('${l.name} (${l.level})',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _locationId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _model,
                    decoration: InputDecoration(
                        labelText: tr(context, 'model'),
                        border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _condition,
                    decoration: InputDecoration(
                        labelText: tr(context, 'condition'),
                        border: const OutlineInputBorder()),
                    items: _conditions
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _condition = v ?? 'GOOD'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: InputDecoration(
                        labelText: tr(context, 'status'),
                        border: const OutlineInputBorder()),
                    items: _statuses
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _status = v ?? 'ACTIVE'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cost,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: tr(context, 'purchaseCost'),
                        border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
