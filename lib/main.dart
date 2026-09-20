import 'package:flutter/material.dart';
import 'features/auth/login_page.dart';

void main() {
runApp(const SmartAssetInventoryApp());
}

class SmartAssetInventoryApp extends StatelessWidget {
const SmartAssetInventoryApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Smart Asset Inventory',

theme: ThemeData(
useMaterial3: true,
colorScheme: ColorScheme.fromSeed(
seedColor: Colors.blue,
),
scaffoldBackgroundColor: Colors.white,
),

home: const LoginPage(),
);
}
}
