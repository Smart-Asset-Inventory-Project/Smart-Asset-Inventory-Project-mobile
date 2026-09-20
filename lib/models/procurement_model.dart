/// AST-FR-03: ربط المشتريات والضمان. للعرض في الفلاتر مع احترام الصلاحية.
class ProcurementInfo {
  final String assetId;
  final String? supplier;
  final String? purchaseOrder;
  final String? invoiceId;
  final String? warrantyProvider;
  final String? warrantyExpiry;
  final String? warrantyTerms;
  final List<String> attachments;

  const ProcurementInfo({
    required this.assetId,
    this.supplier,
    this.purchaseOrder,
    this.invoiceId,
    this.warrantyProvider,
    this.warrantyExpiry,
    this.warrantyTerms,
    this.attachments = const [],
  });

  factory ProcurementInfo.fromJson(Map<String, dynamic> json) =>
      ProcurementInfo(
        assetId: (json['assetId'] ?? '').toString(),
        supplier: json['supplier']?.toString(),
        purchaseOrder: json['purchaseOrder']?.toString(),
        invoiceId: json['invoiceId']?.toString() ?? json['invoice']?.toString(),
        warrantyProvider: json['warrantyProvider']?.toString(),
        warrantyExpiry: json['warrantyExpiry']?.toString(),
        warrantyTerms: json['warrantyTerms']?.toString(),
        attachments: ((json['attachments'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
