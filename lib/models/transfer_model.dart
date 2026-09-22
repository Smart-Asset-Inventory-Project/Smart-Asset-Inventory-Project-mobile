/// AST-FR-04: سجل النقل auditable.
/// الباك اند يسجل النقل فوريا: from/to location+user و transferredAt و reason.
/// لا يوجد approval في الباك اند: كل السجلات القادمة منه completed.
class TransferModel {
  final String id;
  final String assetId;
  final String assetTag;
  final String fromLocation;
  final String toLocation;
  final String? fromCustodian;
  final String? toCustodian;
  final String status; // pending (محلي فقط), completed, approved, rejected
  final String requestedBy;
  final String requestedAt;
  final String? reason;
  final String? decidedBy;
  final String? decidedAt;
  final String? fromUserName;
  final String? toUserName;

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
    this.reason,
    this.decidedBy,
    this.decidedAt,
    this.fromUserName,
    this.toUserName,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    final asset = json['asset'];
    final fromUser = json['fromUser'];
    final toUser = json['toUser'];
    return TransferModel(
      id: json['id'].toString(),
      assetId: (json['assetId'] ?? '').toString(),
      assetTag: ((asset is Map ? asset['assetTag'] : null) ??
              json['assetTag'] ??
              '')
          .toString(),
      fromLocation:
          (json['fromLocationId'] ?? json['fromLocation'] ?? '').toString(),
      toLocation:
          (json['toLocationId'] ?? json['toLocation'] ?? '').toString(),
      fromCustodian:
          (json['fromUserId'] ?? json['fromCustodian'])?.toString(),
      toCustodian: (json['toUserId'] ?? json['toCustodian'])?.toString(),
      status: (json['status'] ?? 'completed').toString(),
      requestedBy: (json['transferredByUserId'] ?? json['requestedBy'] ?? '')
          .toString(),
      requestedAt:
          (json['transferredAt'] ?? json['requestedAt'] ?? '').toString(),
      reason: json['reason']?.toString(),
      decidedBy: json['decidedBy']?.toString(),
      decidedAt: json['decidedAt']?.toString(),
      fromUserName: fromUser is Map ? fromUser['name']?.toString() : null,
      toUserName: toUser is Map ? toUser['name']?.toString() : null,
    );
  }
}
