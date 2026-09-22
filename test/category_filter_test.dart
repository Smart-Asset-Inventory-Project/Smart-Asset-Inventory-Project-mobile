import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_asset_inventory/core/constants/app_constants.dart';
import 'package:smart_asset_inventory/features/assets/assets_list_page.dart';

Future<void> _settleList(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(ListTile).evaluate().isNotEmpty ||
        find.text('No assets found').evaluate().isNotEmpty ||
        find.textContaining('Error').evaluate().isNotEmpty) {
      break;
    }
  }
  await tester.pumpAndSettle();
}

void main() {
  // الباك اند غائب في بيئة الاختبار: شغل mock مؤقتا.
  AppConstants.allowMockFallback = true;

  testWidgets('all category chips render and tap filters the list',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AssetsListPage(),
      ),
    );
    await _settleList(tester);

    for (final c in [
      'All',
      'computer',
      'screen',
      'furniture',
      'printer',
      'lab'
    ]) {
      expect(find.text(c), findsOneWidget, reason: 'chip $c missing');
    }

    await tester.tap(find.text('computer'));
    await tester.pump();
    await _settleList(tester);

    expect(find.textContaining('Computer •'), findsWidgets);
    expect(find.textContaining('Screen •'), findsNothing);
    expect(find.textContaining('Printer •'), findsNothing);
    expect(find.textContaining('Furniture •'), findsNothing);
  });
}
