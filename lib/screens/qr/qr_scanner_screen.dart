import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:servline/core/theme/app_theme.dart';
import 'package:servline/providers/location_provider.dart';
import 'package:servline/widgets/loading_overlay.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  bool _isProcessing = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    // Expected format: servline://location/{locationId}
    // Or just a raw location ID for simplicity
    if (code.startsWith('servline://location/') || code.length > 5) {
      String locationId = code;
      if (code.startsWith('servline://location/')) {
        locationId = code.replaceAll('servline://location/', '');
      }

      if (mounted) {
        await ref.read(locationProvider.notifier).loadLocationById(locationId);
        if (mounted) context.go('/home/select-service/$locationId');
      }
    } else {
      // Invalid code
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid QR Code. Please scan a Servline QR.'),
            backgroundColor: AppColors.error,
          ),
        );
        // Resume scanning after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessing = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),

          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppColors.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          // Flash Button
          Positioned(
            top: 50,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, state, child) {
                    if (!state.isInitialized || !state.isRunning) {
                      return const Icon(Icons.flash_off, color: Colors.grey);
                    }
                    return Icon(
                      state.torchState == TorchState.on
                          ? Icons.flash_on
                          : Icons.flash_off,
                      color: Colors.white,
                    );
                  },
                ),
                onPressed: () => controller.toggleTorch(),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Scan Venue QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Align the code within the frame to scan',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: LoadingSpinner(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

// Custom Shape for QR Overlay (Common pattern)
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final _cutOutSize = cutOutSize;
    final _cutOutBottomOffset = cutOutBottomOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOut;

    final cutOutRect = Rect.fromCenter(
      center: rect.center.translate(0, -_cutOutBottomOffset),
      width: _cutOutSize,
      height: _cutOutSize,
    );

    canvas.saveLayer(rect, backgroundPaint);

    canvas.drawRect(rect, backgroundPaint);

    // Draw cut out
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      boxPaint,
    );

    canvas.restore();

    final borderPath = _getBorderPath(cutOutRect, borderRadius, borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  Path _getBorderPath(Rect rect, double borderRadius, double borderLength) {
    final path = Path();
    // Top left
    path.moveTo(rect.left, rect.top + borderLength);
    path.lineTo(rect.left, rect.top + borderRadius);
    path.arcToPoint(
      Offset(rect.left + borderRadius, rect.top),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(rect.left + borderLength, rect.top);

    // Top right
    path.moveTo(rect.right - borderLength, rect.top);
    path.lineTo(rect.right - borderRadius, rect.top);
    path.arcToPoint(
      Offset(rect.right, rect.top + borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(rect.right, rect.top + borderLength);

    // Bottom right
    path.moveTo(rect.right, rect.bottom - borderLength);
    path.lineTo(rect.right, rect.bottom - borderRadius);
    path.arcToPoint(
      Offset(rect.right - borderRadius, rect.bottom),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(rect.right - borderLength, rect.bottom);

    // Bottom left
    path.moveTo(rect.left + borderLength, rect.bottom);
    path.lineTo(rect.left + borderRadius, rect.bottom);
    path.arcToPoint(
      Offset(rect.left, rect.bottom - borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(rect.left, rect.bottom - borderLength);

    return path;
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
      cutOutBottomOffset: cutOutBottomOffset * t,
    );
  }
}
