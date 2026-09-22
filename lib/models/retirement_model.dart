/// AST-FR-10: سجل تقاعد من /retirements.
class RetirementInfo {
  final String id;
  final String assetId;
  final String? assetTag;
  final String? reason;
  final String? retiredAt;
  final String? approvedBy;
  final String? residualValue;

  const RetirementInfo({
    required this.id,
    required this.assetId,
    this.assetTag,
    this.reason,
    this.retiredAt,
    this.approvedBy,
    this.residualValue,
  });

  factory RetirementInfo.fromJson(Map<String, dynamic> json) {
    final asset = json['asset'];
    return RetirementInfo(
      id: json['id'].toString(),
      assetId: (json['assetId'] ?? '').toString(),
      assetTag: asset is Map ? asset['assetTag']?.toString() : null,
      reason: json['reason']?.toString(),
      retiredAt: json['retiredAt']?.toString(),
      approvedBy: json['approvedBy']?.toString(),
      residualValue: json['residualValue']?.toString(),
    );
  }
}
