/// AST-FR-01/02: يطابق هرم الموقع + بيانات الأصل في البريف.
class LocationModel {
  final String id;
  final String name;
  final String? parentId;
  final String level; // campus, building, college, floor, room, office

  const LocationModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        parentId: json['parentId']?.toString(),
        level: (json['level'] ?? 'room').toString(),
      );
}

class AssetModel {
  final String id;
  final String tag; // QR/Tag فريد - AST-FR-02
  final String? serial;
  final String category;
  final String? brand;
  final String? model;
  final String locationId;
  final String? custodianId;
  final String condition;
  final String status;
  final double? purchaseCost;
  final String? purchaseDate;

  const AssetModel({
    required this.id,
    required this.tag,
    this.serial,
    required this.category,
    this.brand,
    this.model,
    required this.locationId,
    this.custodianId,
    required this.condition,
    required this.status,
    this.purchaseCost,
    this.purchaseDate,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
        id: json['id'].toString(),
        tag: (json['tag'] ?? '').toString(),
        serial: json['serial']?.toString(),
        category: (json['category'] ?? '').toString(),
        brand: json['brand']?.toString(),
        model: json['model']?.toString(),
        locationId: (json['locationId'] ?? '').toString(),
        custodianId: json['custodianId']?.toString(),
        condition: (json['condition'] ?? 'good').toString(),
        status: (json['status'] ?? 'active').toString(),
        purchaseCost: (json['purchaseCost'] as num?)?.toDouble(),
        purchaseDate: json['purchaseDate']?.toString(),
      );
}
