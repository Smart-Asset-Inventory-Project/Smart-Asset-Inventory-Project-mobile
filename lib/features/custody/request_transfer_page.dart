import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/location_service.dart';
import '../../core/services/transfer_service.dart';
import '../../core/services/user_directory.dart';
import '../../models/asset_model.dart';

/// AST-FR-04: تسجيل نقل. الباك اند يسجله فوريا (completed) بلا اعتماد.
/// assetId + toLocationId + reason. رسالة الخطأ من السيرفر.
class RequestTransferPage extends StatefulWidget {
  final String? presetAssetId;
  const RequestTransferPage({super.key, this.presetAssetId});

  @override
  State<RequestTransferPage> createState() => _RequestTransferPageState();
}

class _RequestTransferPageState extends State<RequestTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _asset = TextEditingController();
  final _toCustodian = TextEditingController();
  final _reason = TextEditingController();
  List<LocationModel> _locations = [];
  String? _locationId;
  String? _toUserId;
  bool _loading = false;
  bool _loadingLists = true;

  @override
  void initState() {
    super.initState();
    if (widget.presetAssetId != null) _asset.text = widget.presetAssetId!;
    LocationService().fetchLocations().then((locs) {
      if (!mounted) return;
      setState(() {
        _locations = locs;
        _locationId = locs.isEmpty ? null : locs.last.id;
        _loadingLists = false;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _loadingLists = false);
    });
  }

  @override
  void dispose() {
    _asset.dispose();
    _toCustodian.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'required'))),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await TransferService().requestTransfer(
        assetId: _asset.text.trim(),
        toLocation: _locationId!,
        toCustodian: _toUserId ??
            (_toCustodian.text.trim().isEmpty
                ? null
                : _toCustodian.text.trim()),
        reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'transferRequested'))),
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
      appBar: AppBar(title: Text(tr(context, 'requestTransfer'))),
      body: _loadingLists
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _asset,
                    decoration: InputDecoration(
                        labelText: tr(context, 'assetIdTag'),
                        border: const OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? tr(context, 'required')
                        : null,
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
                    onChanged: (v) => setState(() => _locationId = v),
                  ),
                  const SizedBox(height: 12),
                  // مستخدمون معروفون من الدليل (يتجمع من ردود الباك)
                  Builder(builder: (context) {
                    final known = UserDirectory.instance.all;
                    if (known.isEmpty) {
                      return TextFormField(
                        controller: _toCustodian,
                        decoration: InputDecoration(
                            labelText: tr(context, 'toCustodianOptional'),
                            border: const OutlineInputBorder()),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _toUserId,
                      decoration: InputDecoration(
                          labelText: tr(context, 'toCustodianOptional'),
                          border: const OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('-')),
                        ...known.map((u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.name,
                                overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) => setState(() => _toUserId = v),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reason,
                    decoration: const InputDecoration(
                        labelText: 'reason',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Text(tr(context, 'submitRequest')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

