import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import '../../core/services/catalog_service.dart';
import '../../core/services/location_service.dart';
import '../../core/l10n/strings.dart';
import '../../models/asset_model.dart';
import '../../models/category_model.dart';

/// AST-FR-02: تسجيل أصل جديد.
/// الباك اند يتطلب: assetTag, name, categoryId, locationId.
/// القوائم من /categories و /locations. رسالة الخطأ من السيرفر.
class AddAssetPage extends StatefulWidget {
  const AddAssetPage({super.key});

  @override
  State<AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends State<AddAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final _tag = TextEditingController();
  final _name = TextEditingController();
  final _serial = TextEditingController();
  final _model = TextEditingController();
  final _cost = TextEditingController();
  List<CategoryModel> _categories = [];
  List<LocationModel> _locations = [];
  String? _categoryId;
  String? _locationId;
  String _condition = 'GOOD';
  bool _loading = false;
  bool _loadingLists = true;
  String? _listsError;

  static const _conditions = ['GOOD', 'FAIR', 'POOR', 'DAMAGED'];

  @override
  void initState() {
    super.initState();
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
        _categoryId = cats.isEmpty ? null : cats.first.id;
        _locationId = locs.isEmpty ? null : locs.last.id;
        _loadingLists = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listsError = e.toString().replaceFirst('Exception: ', '');
        _loadingLists = false;
      });
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
    if (_categoryId == null || _locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'required'))),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await AssetService().createAsset({
        'assetTag': _tag.text.trim(),
        'name': _name.text.trim(),
        'serialNumber':
            _serial.text.trim().isEmpty ? null : _serial.text.trim(),
        'categoryId': _categoryId,
        'locationId': _locationId,
        'model': _model.text.trim().isEmpty ? null : _model.text.trim(),
        'condition': _condition,
        'purchaseCost': double.tryParse(_cost.text.trim()),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset created')),
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
      appBar: AppBar(title: Text(tr(context, 'addAsset'))),
      body: _loadingLists
          ? const Center(child: CircularProgressIndicator())
          : _listsError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_listsError!),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _loadingLists = true;
                            _listsError = null;
                          });
                          _loadLists();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        controller: _tag,
                        decoration: InputDecoration(
                            labelText: 'assetTag *',
                            border: const OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? tr(context, 'required')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _name,
                        decoration: InputDecoration(
                            labelText: 'name *',
                            border: const OutlineInputBorder()),
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
                            labelText: '${tr(context, 'category')} *',
                            border: const OutlineInputBorder()),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _categoryId = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _locationId,
                        decoration: InputDecoration(
                            labelText: '${tr(context, 'location')} *',
                            border: const OutlineInputBorder()),
                        items: _locations
                            .map((l) => DropdownMenuItem(
                                value: l.id,
                                child: Text('${l.name} (${l.level})',
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _locationId = v),
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
                              : Text(tr(context, 'createAsset')),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
