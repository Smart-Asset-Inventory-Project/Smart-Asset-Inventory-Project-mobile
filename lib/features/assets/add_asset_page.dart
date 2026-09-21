import 'package:flutter/material.dart';
import '../../core/services/asset_service.dart';
import '../../core/l10n/strings.dart';

/// AST-FR-02: تسجيل أصل جديد بفحص Tag/Serial فريد.
/// يعرض رسالة الباك اند لو مكرر بدل القبول الصامت.
class AddAssetPage extends StatefulWidget {
  const AddAssetPage({super.key});

  @override
  State<AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends State<AddAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final _tag = TextEditingController();
  final _serial = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _location = TextEditingController(text: 'loc-b1-r101');
  final _cost = TextEditingController();
  String _category = 'computer';
  String _condition = 'good';
  bool _loading = false;

  @override
  void dispose() {
    _tag.dispose();
    _serial.dispose();
    _brand.dispose();
    _model.dispose();
    _location.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AssetService().createAsset({
        'tag': _tag.text.trim(),
        'serial': _serial.text.trim().isEmpty ? null : _serial.text.trim(),
        'category': _category,
        'brand': _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        'model': _model.text.trim().isEmpty ? null : _model.text.trim(),
        'locationId': _location.text.trim(),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tag,
              decoration: InputDecoration(
                  labelText: '${tr(context, 'assetsCount')} *', border: const OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? tr(context, 'required') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serial,
              decoration: InputDecoration(
                  labelText: tr(context, 'serial'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                  labelText: tr(context, 'category'), border: const OutlineInputBorder()),
              items: ['computer', 'screen', 'furniture', 'printer', 'lab']
                  .map((c) => DropdownMenuItem(value: c, child: Text(tr(context, c))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'computer'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brand,
                    decoration: InputDecoration(
                        labelText: tr(context, 'brand'), border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _model,
                    decoration: InputDecoration(
                        labelText: tr(context, 'model'), border: const OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: InputDecoration(
                  labelText: '${tr(context, 'location')} *', border: const OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? tr(context, 'required') : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: InputDecoration(
                  labelText: tr(context, 'condition'), border: const OutlineInputBorder()),
              items: ['good', 'needs_repair', 'damaged']
                  .map((c) => DropdownMenuItem(value: c, child: Text(tr(context, c))))
                  .toList(),
              onChanged: (v) => setState(() => _condition = v ?? 'good'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: tr(context, 'purchaseCost'), border: const OutlineInputBorder()),
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
