import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_asset_inventory/features/assets/assets_list_page.dart';

/// مزيج زمن حقيقي + fake حتى يكتمل طلب Dio (رفض سوكيت أو مهلة).
Future<void> _settleList(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
    await tester.pump(const Duration(seconds: 1));
    if (find.byType(ListTile).evaluate().isNotEmpty ||
        find.text('No assets found').evaluate().isNotEmpty ||
        find.textContaining('Error').evaluate().isNotEmpty) {
      break;
    }
  }
  await tester.pump();
}

void main() {
  testWidgets('all category chips render and tap filters the list',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AssetsListPage()));
    await _settleList(tester);

    for (final c in [
      'all',
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

    expect(find.textContaining('computer •'), findsWidgets);
    expect(find.textContaining('screen •'), findsNothing);
    expect(find.textContaining('printer •'), findsNothing);
    expect(find.textContaining('furniture •'), findsNothing);
  });
}
