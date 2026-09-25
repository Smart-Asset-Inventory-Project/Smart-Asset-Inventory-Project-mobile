/// POST /custody-assignments {assetId, userId, notes?} -> 201.
/// Release: PUT /custody-assignments/{id} {returnedAt, notes?}.
/// Duplicate active assignment -> 409.
class CustodyAssignment {
  final String id;
  final String assetId;
  final String userId;
  final String? assignedAt;
  final String? returnedAt;
  final String? notes;

  const CustodyAssignment({
    required this.id,
    required this.assetId,
    required this.userId,
    this.assignedAt,
    this.returnedAt,
    this.notes,
  });

  factory CustodyAssignment.fromJson(Map<String, dynamic> json) =>
      CustodyAssignment(
        id: json['id'].toString(),
        assetId: (json['assetId'] ?? '').toString(),
        userId: (json['userId'] ?? '').toString(),
        assignedAt: json['assignedAt']?.toString(),
        returnedAt: json['returnedAt']?.toString(),
        notes: json['notes']?.toString(),
      );

  bool get isActive => returnedAt == null || returnedAt!.isEmpty;
}
