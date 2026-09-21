import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appSettings.load();
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
