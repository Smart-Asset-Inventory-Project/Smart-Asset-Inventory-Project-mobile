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
    // الباك اند: role كائن {name} أو نص. collegeScope من scopeLocationId.
    final rawRole = json['role'];
    final roleName =
        rawRole is Map ? rawRole['name']?.toString() : rawRole?.toString();
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: UserRole.fromString(roleName),
      collegeScope: json['scopeLocationId']?.toString() ??
          json['collegeId']?.toString() ??
          json['scope']?.toString(),
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
  /// id يطابق عهدة mock حتى تعرض داشبورد الـ custodian بيانات.
  factory UserModel.mock(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('admin')) {
      return UserModel(
        id: 'user-admin',
        name: 'Asset Administrator',
        email: email,
        role: UserRole.admin,
      );
    } else if (lower.contains('procure') || lower.contains('finance')) {
      return UserModel(
        id: 'user-procure',
        name: 'Procurement Viewer',
        email: email,
        role: UserRole.procurement,
      );
    } else if (lower.contains('tech')) {
      return UserModel(
        id: 'user-tech',
        name: 'Maintenance Technician',
        email: email,
        role: UserRole.technician,
      );
    } else if (lower.contains('audit')) {
      return UserModel(
        id: 'user-audit',
        name: 'Auditor Inspector',
        email: email,
        role: UserRole.auditor,
      );
    }
    return UserModel(
      id: 'user-1',
      name: 'Mock Custodian',
      email: email,
      role: UserRole.custodian,
    );
  }
}
