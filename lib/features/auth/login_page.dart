// import 'package:flutter/material.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   bool isAdmin = false;
//   bool obscurePassword = true;
//
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//
//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }
//
//   void login() {
//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();
//
//     final selectedRole = isAdmin ? 'admin' : 'user';
//
//     debugPrint('Email: $email');
//     debugPrint('Password: $password');
//     debugPrint('Selected Role: $selectedRole');
//
//     // Later:
//     // Send email + password to Backend
//     // Backend returns the real user role.
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//
//                 // Logo
//                 Center(
//                   child: Container(
//                     width: 120,
//                     height: 120,
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       //shape: BoxShape.circle,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Icon(
//                       Icons.inventory_2_outlined,
//                       size: 42,
//                       color: Colors.blue,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 44),
//
//                 // App name
//                 const Text(
//                   'Smart Asset Inventory',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 25,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//
//                 const SizedBox(height: 8),
//
//                 const Text(
//                   'Manage Assets Smarter',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                   ),
//                 ),
//
//
//                 // Role selection
//
//
//
//                 const SizedBox(height: 18),
//
//                 // Email
//                 const Text(
//                   'Email',
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//
//                 const SizedBox(height: 8),
//
//                 TextField(
//                   controller: emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: InputDecoration(
//                     hintText: 'Enter your email',
//                     prefixIcon: const Icon(Icons.email_outlined),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Password
//                 const Text(
//                   'Password',
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//
//                 const SizedBox(height: 8),
//
//                 TextField(
//                   controller: passwordController,
//                   obscureText: obscurePassword,
//                   decoration: InputDecoration(
//                     hintText: 'Enter your password',
//                     prefixIcon: const Icon(Icons.lock_outline),
//                     suffixIcon: IconButton(
//                       onPressed: () {
//                         setState(() {
//                           obscurePassword = !obscurePassword;
//                         });
//                       },
//                       icon: Icon(
//                         obscurePassword
//                             ? Icons.visibility_outlined
//                             : Icons.visibility_off_outlined,
//                       ),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 30),
//
//                 // Login button
//                 SizedBox(
//                   height: 52,
//                   child: ElevatedButton(
//                     onPressed: login,
//                     child: const Text(
//                       'Login',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
// class _RoleCard extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   const _RoleCard({
//     required this.title,
//     required this.icon,
//     required this.isSelected,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected
//                 ? Colors.blue
//                 : Colors.grey.shade300,
//             width: isSelected ? 2 : 1,
//           ),
//           color: isSelected
//               ? Colors.blue.shade50
//               : Colors.white,
//         ),
//         child: Column(
//           children: [
//             Icon(
//               icon,
//               size: 28,
//               color: isSelected
//                   ? Colors.blue
//                   : Colors.grey,
//             ),
//
//             const SizedBox(height: 8),
//
//             Text(
//               title,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: isSelected
//                     ? Colors.blue
//                     : Colors.grey.shade700,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_settings.dart';
import '../../core/services/auth_service.dart';
import '../dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isAdmin = false;
  bool obscurePassword = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Warm-up: wakes the sleeping Vercel function while the user types,
    // so the real login (cold start ~5s) feels instant. Fire-and-forget:
    // any response (even 401) means warm. Dev-mock unaffected.
    _warmBackend();
  }

  Future<void> _warmBackend() async {
    try {
      await Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ).get('/assets', queryParameters: {'limit': '1'}).timeout(
            const Duration(seconds: 12),
          );
    } catch (_) {
      // ignored: login works the same on a cold backend, just slower once.
    }
  }

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = AuthService();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    // Validate all form fields first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() => _loading = true);
    try {
      final user = await _auth.login(email: email, password: password);
      if (!mounted) return;
      // AST Auth: الدور الحقيقي يأتي من الباك اند داخل التوكن/اليوزر.
      // نمرر اليوزر مباشرة فيوفر Dashboard رحلة /auth/me تسلسلية.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage(user: user)),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '');
      // مفاتيح أخطاء الشبكة تترجم، رسائل السيرفر تعرض كما هي.
      final msg = raw == 'timeoutRetry' || raw == 'noInternet'
          ? tr(context, raw)
          : raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Top settings controls
            Positioned(
              top: 0,
              right: 8,
              left: 8,
              child: AnimatedBuilder(
                animation: appSettings,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => appSettings.toggleLocale(),
                      child: Text(appSettings.isArabic ? 'EN' : 'عربي'),
                    ),
                    IconButton(
                      tooltip: tr(context, 'darkMode'),
                      onPressed: () => appSettings.toggleTheme(),
                      icon: Icon(appSettings.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      Center(
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 44),

                      // App name
                      Text(
                        tr(context, 'appName'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      // App description
                      Text(
                        tr(context, 'tagline'),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 18),

                      // Email label
                      Text(
                        tr(context, 'email'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      // Email field
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr(context, 'enterEmail');
                          }
                          final emailRegex = RegExp(
                            r'^[\w\.-]+@([\w-]+\.)+[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return tr(context, 'invalidEmail');
                          }
                          return null;
                        },

                        decoration: InputDecoration(
                          hintText: tr(context, 'enterEmail'),
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password label
                      Text(
                        tr(context, 'password'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      // Password field
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr(context, 'enterPassword');
                          }
                          if (value.length < 6) {
                            return tr(context, 'shortPassword');
                          }
                          return null;
                        },

                        decoration: InputDecoration(
                          hintText: tr(context, 'enterPassword'),
                          prefixIcon: const Icon(Icons.lock_outline),

                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Login button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : login,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  tr(context, 'login'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
