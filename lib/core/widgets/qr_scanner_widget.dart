import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// AST-FR-07: مسح QR حقيقي بالكاميرا + إدخال يدوي كبديل.
/// onScanned يستقبل Tag المقروء مرة واحدة لكل مسحة.
class QrScannerWidget extends StatefulWidget {
  final ValueChanged<String> onScanned;
  const QrScannerWidget({super.key, required this.onScanned});

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  final _ctrl = TextEditingController();
  final _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _locked = false;
  bool _showManual = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  void _emit(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty || _locked) return;
    _locked = true;
    widget.onScanned(v);
    // فك القفل بعد ثانيتين للمسحة التالية
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            child: MobileScanner(
              controller: _scannerCtrl,
              onDetect: (capture) {
                for (final b in capture.barcodes) {
                  _emit(b.rawValue);
                  if (_locked) break;
                }
              },
              errorBuilder: (context, error, child) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Camera unavailable — use manual entry below',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        TextButton.icon(
          icon: Icon(
              _showManual ? Icons.expand_less : Icons.keyboard_outlined),
          label: Text(_showManual ? 'Hide manual entry' : 'Enter tag manually'),
          onPressed: () => setState(() => _showManual = !_showManual),
        ),
        if (_showManual)
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'Asset tag (e.g. AST-B1-1001)',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) widget.onScanned(v.trim());
            },
          ),
      ],
    );
  }
}
