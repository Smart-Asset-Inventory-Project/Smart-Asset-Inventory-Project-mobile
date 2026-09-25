import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_settings.dart';

/// App settings: appearance (light/dark) + language.
/// Opened from the drawer; applies instantly app-wide, persisted locally.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'settings'))),
      body: AnimatedBuilder(
        animation: appSettings,
        builder: (_, __) => ListView(
          children: [
            SwitchListTile(
              secondary: Icon(
                appSettings.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              title: Text(tr(context, 'darkMode')),
              value: appSettings.isDark,
              onChanged: (_) => appSettings.toggleTheme(),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(tr(context, 'language')),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('EN')),
                  ButtonSegment(value: 'ar', label: Text('عربي')),
                ],
                selected: {
                  appSettings.isArabic ? 'ar' : 'en',
                },
                onSelectionChanged: (s) {
                  if ((s.first == 'ar') != appSettings.isArabic) {
                    appSettings.toggleLocale();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
