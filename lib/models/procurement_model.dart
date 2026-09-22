/// AST-FR-03: نماذج المشتريات من الباك اند.
class SupplierInfo {
  final String id;
  final String name;
  final String? email;
  final String? phone;

  const SupplierInfo({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory SupplierInfo.fromJson(Map<String, dynamic> json) => SupplierInfo(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
      );
}

class InvoiceInfo {
  final String id;
  final String invoiceNumber;
  final String? amount;
  final String? issueDate;
  final String? status;

  const InvoiceInfo({
    required this.id,
    required this.invoiceNumber,
    this.amount,
    this.issueDate,
    this.status,
  });

  factory InvoiceInfo.fromJson(Map<String, dynamic> json) => InvoiceInfo(
        id: json['id'].toString(),
        invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
        amount: json['amount']?.toString(),
        issueDate: json['issueDate']?.toString(),
        status: json['status']?.toString(),
      );
}

class PurchaseOrderInfo {
  final String id;
  final String assetId;
  final String orderNumber;
  final String? orderDate;
  final String? totalAmount;
  final String? status;
  final String? supplierName;
  final List<InvoiceInfo> invoices;

  const PurchaseOrderInfo({
    required this.id,
    required this.assetId,
    required this.orderNumber,
    this.orderDate,
    this.totalAmount,
    this.status,
    this.supplierName,
    this.invoices = const [],
  });

  factory PurchaseOrderInfo.fromJson(Map<String, dynamic> json) {
    final sup = json['supplier'];
    final inv = json['invoices'];
    return PurchaseOrderInfo(
      id: json['id'].toString(),
      assetId: (json['assetId'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      orderDate: json['orderDate']?.toString(),
      totalAmount: json['totalAmount']?.toString(),
      status: json['status']?.toString(),
      supplierName: sup is Map ? sup['name']?.toString() : null,
      invoices: inv is List
          ? inv
              .map((e) => InvoiceInfo.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }
}

class WarrantyInfo {
  final String id;
  final String assetId;
  final String? provider;
  final String? startDate;
  final String? endDate;
  final String? terms;

  const WarrantyInfo({
    required this.id,
    required this.assetId,
    this.provider,
    this.startDate,
    this.endDate,
    this.terms,
  });

  factory WarrantyInfo.fromJson(Map<String, dynamic> json) => WarrantyInfo(
        id: json['id'].toString(),
        assetId: (json['assetId'] ?? '').toString(),
        provider: json['provider']?.toString(),
        startDate: json['startDate']?.toString(),
        endDate: json['endDate']?.toString(),
        terms: json['terms']?.toString(),
      );
}

/// ملخص الشراء/الضمان لأصل واحد (شاشة Procurement).
class ProcurementInfo {
  final String assetId;
  final String? supplier;
  final String? purchaseOrder;
  final String? purchaseDate;
  final String? purchaseAmount;
  final String? invoiceId;
  final List<String> invoices;
  final String? warrantyProvider;
  final String? warrantyExpiry;
  final String? warrantyTerms;

  const ProcurementInfo({
    required this.assetId,
    this.supplier,
    this.purchaseOrder,
    this.purchaseDate,
    this.purchaseAmount,
    this.invoiceId,
    this.invoices = const [],
    this.warrantyProvider,
    this.warrantyExpiry,
    this.warrantyTerms,
  });

  factory ProcurementInfo.fromJson(Map<String, dynamic> json) =>
      ProcurementInfo(
        assetId: (json['assetId'] ?? '').toString(),
        supplier: json['supplier']?.toString(),
        purchaseOrder: json['purchaseOrder']?.toString(),
        purchaseDate: json['purchaseDate']?.toString(),
        purchaseAmount: json['purchaseAmount']?.toString(),
        invoiceId:
            json['invoiceId']?.toString() ?? json['invoice']?.toString(),
        invoices: ((json['invoices'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        warrantyProvider: json['warrantyProvider']?.toString(),
        warrantyExpiry: json['warrantyExpiry']?.toString(),
        warrantyTerms: json['warrantyTerms']?.toString(),
      );
}
