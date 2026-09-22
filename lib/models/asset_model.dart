/// AST-FR-01: موقع الباك اند {id,name,code,type,parentId}.
class LocationModel {
  final String id;
  final String name;
  final String? parentId;
  final String level; // room, floor, building, campus...
  final String? code;

  const LocationModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
    this.code,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        parentId: json['parentId']?.toString(),
        level: (json['type'] ?? json['level'] ?? 'room').toString(),
        code: json['code']?.toString(),
      );
}

/// AST-FR-02: أصل الباك اند.
/// assetTag, serialNumber, value(string), status/condition أحرف كبيرة,
/// category/location كائنات, assignedToUserId, qrCodeUrl.
class AssetModel {
  final String id;
  final String tag;
  final String? serial;
  final String category;
  final String? categoryId;
  final String? brand;
  final String? model;
  final String? name;
  final String locationId;
  final String? locationName;
  final String? custodianId;
  final String? custodianName;
  final String condition;
  final String status;
  final double? purchaseCost;
  final String? purchaseDate;
  final String? qrCodeUrl;

  const AssetModel({
    required this.id,
    required this.tag,
    this.serial,
    required this.category,
    this.categoryId,
    this.brand,
    this.model,
    this.name,
    required this.locationId,
    this.locationName,
    this.custodianId,
    this.custodianName,
    required this.condition,
    required this.status,
    this.purchaseCost,
    this.purchaseDate,
    this.qrCodeUrl,
  });

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final loc = json['location'];
    final assigned = json['assignedTo'];
    return AssetModel(
      id: json['id'].toString(),
      tag: (json['assetTag'] ?? json['tag'] ?? '').toString(),
      serial: (json['serialNumber'] ?? json['serial'])?.toString(),
      category: (cat is Map
              ? cat['name']
              : (json['category'] ?? ''))
          .toString(),
      categoryId: (json['categoryId'] ?? (cat is Map ? cat['id'] : null))
          ?.toString(),
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      name: json['name']?.toString(),
      locationId: (json['locationId'] ?? '').toString(),
      locationName: loc is Map ? loc['name']?.toString() : null,
      custodianId: (json['assignedToUserId'] ?? json['custodianId'])
          ?.toString(),
      custodianName: assigned is Map ? assigned['name']?.toString() : null,
      condition: (json['condition'] ?? 'good').toString(),
      status: (json['status'] ?? 'active').toString(),
      purchaseCost:
          _num(json['purchaseCost']) ?? _num(json['value']),
      purchaseDate: json['purchaseDate']?.toString(),
      qrCodeUrl: json['qrCodeUrl']?.toString(),
    );
  }
}
