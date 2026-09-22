import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/procurement_service.dart';
import '../../models/procurement_model.dart';

/// AST-FR-03/08: نظرة المشتريات العامة.
/// أوامر الشراء + الفواتير + الضمانات من الباك اند الحقيقي.
class ProcurementOverviewPage extends StatefulWidget {
  const ProcurementOverviewPage({super.key});

  @override
  State<ProcurementOverviewPage> createState() =>
      _ProcurementOverviewPageState();
}

class _ProcurementOverviewPageState extends State<ProcurementOverviewPage> {
  late Future<
      (List<PurchaseOrderInfo>, List<InvoiceInfo>, List<WarrantyInfo>,
          List<SupplierInfo>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<
      (List<PurchaseOrderInfo>, List<InvoiceInfo>, List<WarrantyInfo>,
          List<SupplierInfo>)> _load() async {
    final svc = ProcurementService();
    final pos = await svc.fetchPurchaseOrders();
    final invs = await svc.fetchInvoices();
    final wars = await svc.fetchWarranties();
    final sups = await svc.fetchSuppliers();
    return (pos, invs, wars, sups);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'procurementTitle'))),
      body: FutureBuilder<
          (List<PurchaseOrderInfo>, List<InvoiceInfo>, List<WarrantyInfo>,
              List<SupplierInfo>)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final pos = snap.data?.$1 ?? [];
          final invs = snap.data?.$2 ?? [];
          final wars = snap.data?.$3 ?? [];
          final sups = snap.data?.$4 ?? [];
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _header(context,
                  '${tr(context, 'purchaseOrders')} (${pos.length})'),
              ...pos.take(20).map((p) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.shopping_cart_outlined),
                      title: Text(p.orderNumber,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${p.supplierName ?? '-'} • ${p.totalAmount ?? '-'}'),
                      trailing: Text(p.status ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ),
                  )),
              const SizedBox(height: 16),
              _header(
                  context, '${tr(context, 'invoices')} (${invs.length})'),
              ...invs.take(20).map((i) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(i.invoiceNumber,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${i.amount ?? '-'} • ${i.status ?? ''}'),
                    ),
                  )),
              const SizedBox(height: 16),
              _header(
                  context, '${tr(context, 'warranties')} (${wars.length})'),
              ...wars.take(20).map((w) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.verified_outlined),
                      title: Text(w.provider ?? '-',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text('${w.startDate ?? '-'} → ${w.endDate ?? '-'}'),
                    ),
                  )),
              const SizedBox(height: 16),
              _header(context, 'Suppliers (${sups.length})'),
              ...sups.map((s) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.store_outlined),
                      title: Text(s.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${s.email ?? '-'} • ${s.phone ?? '-'}'),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
