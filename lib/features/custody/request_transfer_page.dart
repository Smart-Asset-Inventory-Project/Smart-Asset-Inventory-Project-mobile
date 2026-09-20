import 'package:flutter/material.dart';
import '../../core/services/transfer_service.dart';

/// AST-FR-04: نموذج طلب نقل. العهدة الحالية تظل سارية حتى الاعتماد.
class RequestTransferPage extends StatefulWidget {
  final String? presetAssetId;
  const RequestTransferPage({super.key, this.presetAssetId});

  @override
  State<RequestTransferPage> createState() => _RequestTransferPageState();
}

class _RequestTransferPageState extends State<RequestTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _asset = TextEditingController();
  final _toLocation = TextEditingController();
  final _toCustodian = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.presetAssetId != null) _asset.text = widget.presetAssetId!;
  }

  @override
  void dispose() {
    _asset.dispose();
    _toLocation.dispose();
    _toCustodian.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await TransferService().requestTransfer(
        assetId: _asset.text.trim(),
        toLocation: _toLocation.text.trim(),
        toCustodian:
            _toCustodian.text.trim().isEmpty ? null : _toCustodian.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer requested (pending approval)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Transfer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _asset,
              decoration: const InputDecoration(
                  labelText: 'Asset ID / Tag', border: OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _toLocation,
              decoration: const InputDecoration(
                  labelText: 'To location ID', border: OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _toCustodian,
              decoration: const InputDecoration(
                  labelText: 'To custodian (optional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Submit request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
