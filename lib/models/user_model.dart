import '../core/constants/app_enums.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? collegeScope;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.collegeScope,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: UserRole.fromString(json['role']?.toString()),
      collegeScope: json['collegeId']?.toString() ?? json['scope']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'collegeId': collegeScope,
      };

  /// مستخدم تجريبي عند غياب الباك اند فقط.
  factory UserModel.mock(String email) => UserModel(
        id: 'mock-1',
        name: 'Mock User',
        email: email,
        role: UserRole.custodian,
      );
}
