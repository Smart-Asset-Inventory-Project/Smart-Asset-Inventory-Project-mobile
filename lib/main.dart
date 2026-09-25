import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appSettings.load();
  if (kDebugMode) {
    // Run-console proof of the active data source.
    debugPrint(
        'Data source: ${AppConstants.allowMockFallback ? 'MOCK fallback ON' : 'backend only'} (${AppConstants.baseUrl})');
  }
  // Expired session anywhere → back to login (set once, no cycles:
  // ApiService never imports main).
  ApiService.onUnauthorized = () {
    ApiService.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  };
  runApp(const SmartAssetInventoryApp());
}

class SmartAssetInventoryApp extends StatelessWidget {
  const SmartAssetInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // أي تغيير ثيم/لغة يعيد بناء التطبيق كله فوريا.
    return AnimatedBuilder(
      animation: appSettings,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: ApiService.navigatorKey,
        title: 'Smart Asset Inventory',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: appSettings.themeMode,
        locale: appSettings.locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoginPage(),
      ),
    );
  }
}

//
// Role Email Password
// ADMIN admin@assethub.local Admin@123
// PROCUREMENT procurement@assethub.local Test@123
// CUSTODIAN custodian@assethub.local Test@123
// TECHNICIAN technician@assethub.local Test@123
// AUDITOR auditor@assethub.local Test@123
// These are the demo credentials defined in seed.js.