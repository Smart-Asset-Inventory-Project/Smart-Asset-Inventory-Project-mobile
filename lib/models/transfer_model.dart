/// AST-FR-04: النقل عهدة فريدة + سجل auditable.
/// كل حركة حدث بـ actor و timestamp ولا تعدل تاريخيا.
class TransferModel {
  final String id;
  final String assetId;
  final String assetTag;
  final String fromLocation;
  final String toLocation;
  final String? fromCustodian;
  final String? toCustodian;
  final String status; // pending, approved, rejected
  final String requestedBy;
  final String requestedAt;
  final String? decidedBy;
  final String? decidedAt;

  const TransferModel({
    required this.id,
    required this.assetId,
    required this.assetTag,
    required this.fromLocation,
    required this.toLocation,
    this.fromCustodian,
    this.toCustodian,
    required this.status,
    required this.requestedBy,
    required this.requestedAt,
    this.decidedBy,
    this.decidedAt,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) => TransferModel(
        id: json['id'].toString(),
        assetId: (json['assetId'] ?? '').toString(),
        assetTag: (json['assetTag'] ?? '').toString(),
        fromLocation: (json['fromLocation'] ?? '').toString(),
        toLocation: (json['toLocation'] ?? '').toString(),
        fromCustodian: json['fromCustodian']?.toString(),
        toCustodian: json['toCustodian']?.toString(),
        status: (json['status'] ?? 'pending').toString(),
        requestedBy: (json['requestedBy'] ?? '').toString(),
        requestedAt: (json['requestedAt'] ?? '').toString(),
        decidedBy: json['decidedBy']?.toString(),
        decidedAt: json['decidedAt']?.toString(),
      );
}
