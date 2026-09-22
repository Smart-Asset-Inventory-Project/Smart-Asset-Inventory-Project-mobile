import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_asset_inventory/main.dart';

void main() {
  testWidgets('App launches and renders LoginPage with logo and inputs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAssetInventoryApp());
    await tester.pumpAndSettle();

    // Verify logo and inputs render
    expect(find.byType(Image), findsWidgets);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
