import 'package:flutter/material.dart';
import '../constants/app_enums.dart';
import '../services/auth_service.dart';
import '../../models/user_model.dart';

/// يخفي الزر عن دور الـ auditor (قراءة فقط).
/// الـBackend هو الحارس الحقيقي؛ هذا تجميل UI فقط.
class HideForAuditor extends StatelessWidget {
  final Widget child;
  const HideForAuditor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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
