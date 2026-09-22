import 'package:flutter/material.dart';
import '../../core/constants/app_enums.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/procurement_service.dart';
import '../../models/procurement_model.dart';
import '../../models/user_model.dart';

/// AST-FR-03: شاشة المشتريات والضمان.
/// procurement/admin/auditor فقط؛ باقي الأدوار يرى رسالة منع.
class ProcurementPage extends StatefulWidget {
  final String assetId;
  const ProcurementPage({super.key, required this.assetId});

  @override
  State<ProcurementPage> createState() => _ProcurementPageState();
}

class _ProcurementPageState extends State<ProcurementPage> {
  late Future<(UserModel?, ProcurementInfo)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(UserModel?, ProcurementInfo)> _load() async {
    final user = await AuthService().currentUser();
    final info =
        await ProcurementService().fetchForAsset(widget.assetId);
    return (user, info);
  }

  bool _allowed(UserRole r) =>
      r == UserRole.admin ||
      r == UserRole.procurement ||
      r == UserRole.auditor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Procurement & Warranty')),
      body: FutureBuilder<(UserModel?, ProcurementInfo)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final user = snap.data!.$1;
          final info = snap.data!.$2;
          if (user == null || !_allowed(user.role)) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Access denied: invoice and warranty evidence require procurement permission (AST-FR-03).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _row('Supplier', info.supplier ?? '-'),
              _row('Purchase order', info.purchaseOrder ?? '-'),
              _row('Order date', info.purchaseDate ?? '-'),
              _row('Amount', info.purchaseAmount ?? '-'),
              _row('Invoice', info.invoiceId ?? '-'),
              if (info.invoices.length > 1)
                _row('All invoices', info.invoices.join(', ')),
              const Divider(height: 24),
              _row('Warranty provider', info.warrantyProvider ?? '-'),
              _row('Warranty expiry', info.warrantyExpiry ?? '-'),
              _row('Warranty terms', info.warrantyTerms ?? '-'),
              if (info.supplier == null && info.warrantyProvider == null)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'No procurement records linked to this asset.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
                width: 140,
                child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(
                child: Text(v,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
