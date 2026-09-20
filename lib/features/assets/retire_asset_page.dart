import 'package:flutter/material.dart';
import '../../core/services/retirement_service.dart';

/// AST-FR-10: نموذج تقاعد بسبب. يتطلب اعتماد إداري في الباك اند.
class RetireAssetPage extends StatefulWidget {
  final String assetId;
  final String assetTag;
  const RetireAssetPage(
      {super.key, required this.assetId, required this.assetTag});

  @override
  State<RetireAssetPage> createState() => _RetireAssetPageState();
}

class _RetireAssetPageState extends State<RetireAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _evidence = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reason.dispose();
    _evidence.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await RetirementService().retire(
        assetId: widget.assetId,
        reason: _reason.text.trim(),
        evidence: _evidence.text.trim().isEmpty
            ? null
            : _evidence.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Retirement submitted for approval (read-only after approval)')),
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
      appBar: AppBar(title: Text('Retire ${widget.assetTag}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Retired asset becomes read-only and stays in audit reports.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reason,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _evidence,
              decoration: const InputDecoration(
                labelText: 'Evidence ref (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit retirement',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
