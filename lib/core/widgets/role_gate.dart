import 'package:flutter/material.dart';
import '../constants/app_enums.dart';
import '../services/auth_service.dart';
import '../../models/user_model.dart';

/// يخفي الزر عن دور الـ auditor (قراءة فقط).
/// مرر role عند توفره (Dashboard) فيحسم فوريا بدون /auth/me.
/// بدون role: يستخدم ذاكرة AuthService (<60s) فلا request مكرر.
/// الـBackend هو الحارس الحقيقي؛ هذا تجميل UI فقط.
class HideForAuditor extends StatelessWidget {
  final Widget child;
  final UserRole? role;
  const HideForAuditor({super.key, required this.child, this.role});

  @override
  Widget build(BuildContext context) {
    if (role != null) {
      if (role == UserRole.auditor) return const SizedBox.shrink();
      return child;
    }
    return FutureBuilder<UserModel?>(
      future: AuthService().currentUser(),
      builder: (context, snap) {
        if (snap.data?.role == UserRole.auditor) {
          return const SizedBox.shrink();
        }
        return child;
      },
    );
  }
}
