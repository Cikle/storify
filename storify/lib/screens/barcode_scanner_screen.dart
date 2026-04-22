import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storify/utils/constants.dart';

// Scanner screen – returns the scanned value
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _torchOn = false;
  bool _scanned = false;
  bool _hasError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode / QR scannen'),
        actions: _hasError
            ? []
            : [
                IconButton(
                  icon: Icon(
                    _torchOn ? Icons.flash_on : Icons.flash_off,
                    color: _torchOn
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _controller.toggleTorch();
                    setState(() => _torchOn = !_torchOn);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios_outlined),
                  onPressed: () => _controller.switchCamera(),
                ),
              ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              // Set error in next frame so the overlay sits on top
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasError) setState(() => _hasError = true);
              });
              return const SizedBox.expand();
            },
          ),

          // Zielrahmen + Hinweis nur anzeigen wenn kein Fehler
          if (!_hasError) ...[
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: CustomPaint(
                  painter: _CornerFramePainter(color: AppColors.primary),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hold barcode or QR code inside the frame',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Fehler-Overlay ganz oben im Stack (deckt alles ab)
          if (_hasError)
            Positioned.fill(
              child: Container(
                color: AppColors.background,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(32),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.no_photography_outlined,
                          color: AppColors.error,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Camera access denied',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'The app needs camera access to scan barcodes. Please allow access in your device settings.',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async => await openAppSettings(),
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Open settings'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            foregroundColor: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _scanned = true;
    Navigator.pop(context, value);
  }
}

// Corner markers instead of a full border frame
class _CornerFramePainter extends CustomPainter {
  final Color color;
  const _CornerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const r = 12.0; // corner radius
    const len = 32.0; // length of each corner arm

    // Oben-Links
    canvas.drawPath(
      Path()
        ..moveTo(r, 0)
        ..lineTo(len, 0)
        ..moveTo(0, r)
        ..lineTo(0, len),
      paint,
    );
    // Oben-Rechts
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..moveTo(size.width, r)
        ..lineTo(size.width, len),
      paint,
    );
    // Unten-Links
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height - r)
        ..moveTo(r, size.height)
        ..lineTo(len, size.height),
      paint,
    );
    // Unten-Rechts
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width - r, size.height)
        ..moveTo(size.width, size.height - len)
        ..lineTo(size.width, size.height - r),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerFramePainter old) => old.color != color;
}
