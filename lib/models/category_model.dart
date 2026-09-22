/// فئة أصل من /categories {id,name,code}.
class CategoryModel {
  final String id;
  final String name;
  final String? code;

  const CategoryModel({required this.id, required this.name, this.code});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        code: json['code']?.toString(),
      );
}
