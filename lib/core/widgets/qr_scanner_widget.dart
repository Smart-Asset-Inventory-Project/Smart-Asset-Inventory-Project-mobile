import 'package:flutter/material.dart';

/// AST-FR-07: واجهة مسح QR.
/// نسخة ميدانية بسيطة: إدخال Tag يدوي + زر محاكاة مسح.
/// عند تركيب mobile_scanner لاحقا يستبدل _simulate فقط.
class QrScannerWidget extends StatelessWidget {
  final ValueChanged<String> onScanned;
  const QrScannerWidget({super.key, required this.onScanned});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_scanner, size: 72, color: Colors.blue),
        const SizedBox(height: 8),
        const Text('Scan asset QR or enter tag manually'),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Asset tag (e.g. AST-B1-1001)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) onScanned(v.trim());
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Simulate scan'),
                onPressed: () {
                  final v = ctrl.text.trim().isEmpty
                      ? 'AST-B1-1003'
                      : ctrl.text.trim();
                  onScanned(v);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
