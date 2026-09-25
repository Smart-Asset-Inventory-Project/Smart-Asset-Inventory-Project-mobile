import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/asset_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/transfer_outbox.dart';
import '../../core/services/transfer_service.dart';
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
  final _reason = TextEditingController();
  List<LocationModel> _locations = [];
  List<AssetModel> _assets = [];
  String? _locationId;
  String? _assetId;
  bool _loading = false;
  bool _loadingLists = true;

  @override
  void initState() {
    super.initState();
    if (widget.presetAssetId != null) _asset.text = widget.presetAssetId!;
    Future.wait([
      LocationService().fetchLocations(),
      // Asset dropdown so the backend gets a real assetId (free-text
      // tags 404 on POST /transfers). Best-effort: falls back to text.
      AssetService().fetchAssets().then((v) => v, onError: (_) => []),
    ]).then((results) {
      if (!mounted) return;
      final locs = results[0] as List<LocationModel>;
      final assets = (results[1] as List).cast<AssetModel>();
      setState(() {
        _locations = locs;
        _locationId = locs.isEmpty ? null : locs.last.id;
        _assets = assets;
        if (widget.presetAssetId != null &&
            assets.any((a) => a.id == widget.presetAssetId)) {
          _assetId = widget.presetAssetId;
        }
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
    _reason.dispose();
    super.dispose();
  }

  /// Dropdown needs the preset inside the fetched list; otherwise the
  /// user would be stuck with an unselectable value — fall back to text.
  bool get _useDropdown =>
      _assets.isNotEmpty &&
      (widget.presetAssetId == null ||
          _assets.any((a) => a.id == widget.presetAssetId));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final assetId = _assetId ?? _asset.text.trim();
    if (assetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'required'))),
      );
      return;
    }
    if (_locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'required'))),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await TransferService().requestTransfer(
        assetId: assetId,
        toLocation: _locationId!,
        reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'transferRequested'))),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      // 403 (no permission) or 5xx (broken backend): keep on device.
      if (RegExp(r'\((403|5\d\d)\)').hasMatch(msg)) {
        // Backend refuses this role — keep the request on the device as
        // pending instead of losing it. Re-sendable from the Pending tab.
        await TransferOutbox.add(OutboxTransfer(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          assetId: assetId,
          toLocationId: _locationId!,
          reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
        ));
        if (!mounted) return;
        Navigator.pop(context, 'local');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No permission — request kept on this device as pending')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
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
                  // Real asset ids: the backend 404s unknown/tags.
                  if (_useDropdown)
                    DropdownButtonFormField<String>(
                      initialValue: _assetId,
                      decoration: InputDecoration(
                          labelText: '${tr(context, 'assetIdTag')} *',
                          border: const OutlineInputBorder()),
                      items: _assets
                          .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                  '${a.tag}${(a.name ?? '').isEmpty ? '' : ' • ${a.name}'}',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _assetId = v),
                      validator: (v) => v == null || v.isEmpty
                          ? tr(context, 'required')
                          : null,
                    )
                  else
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
                  // Custody is a separate API (POST /custody-assignments);
                  // transfers only move location + preserve custody.
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

