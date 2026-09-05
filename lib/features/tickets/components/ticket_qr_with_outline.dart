import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:qr/qr.dart";

class TicketQrWithOutline extends StatelessWidget {
  const TicketQrWithOutline({super.key, required this.data});

  final String data;

  static const double _outlineSize = 200;
  static const double _qrSize = 152;

  @override
  Widget build(BuildContext context) {
    final payload = data.isNotEmpty ? data : "dth-ticket";

    return SizedBox(
      width: _outlineSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            ImageAssets.ticketQrCodeOutline,
            width: _outlineSize,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 4,
              bottom: 8,
              left: 4,
              right: 4,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: Colors.white,
                child: CustomPaint(
                  size: const Size.square(_qrSize),
                  painter: _RoundedTicketQrPainter(data: payload),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws circular data modules and rounded-square finder eyes (not full circles).
class _RoundedTicketQrPainter extends CustomPainter {
  _RoundedTicketQrPainter({required this.data});

  final String data;

  /// Finder eye outer corner radius as a fraction of the 7-module eye size.
  static const double _eyeCornerFraction = 0.28;

  @override
  void paint(Canvas canvas, Size size) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    final moduleCount = qrImage.moduleCount;
    final moduleSize = size.shortestSide / moduleCount;
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final clear = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Data modules (skip finder eye regions — drawn separately).
    for (var y = 0; y < moduleCount; y++) {
      for (var x = 0; x < moduleCount; x++) {
        if (_inFinderEye(x, y, moduleCount)) continue;
        if (!qrImage.isDark(y, x)) continue;

        final cx = (x + 0.5) * moduleSize;
        final cy = (y + 0.5) * moduleSize;
        canvas.drawCircle(Offset(cx, cy), moduleSize * 0.42, paint);
      }
    }

    _drawFinderEye(canvas, paint, clear, moduleSize, 0, 0);
    _drawFinderEye(canvas, paint, clear, moduleSize, moduleCount - 7, 0);
    _drawFinderEye(canvas, paint, clear, moduleSize, 0, moduleCount - 7);
  }

  bool _inFinderEye(int x, int y, int moduleCount) {
    final inTopLeft = x < 7 && y < 7;
    final inTopRight = x >= moduleCount - 7 && y < 7;
    final inBottomLeft = x < 7 && y >= moduleCount - 7;
    return inTopLeft || inTopRight || inBottomLeft;
  }

  void _drawFinderEye(
    Canvas canvas,
    Paint dark,
    Paint light,
    double moduleSize,
    int originX,
    int originY,
  ) {
    final eyeSize = moduleSize * 7;
    final outer = Rect.fromLTWH(
      originX * moduleSize,
      originY * moduleSize,
      eyeSize,
      eyeSize,
    );
    final corner = Radius.circular(eyeSize * _eyeCornerFraction);

    // Outer rounded square.
    canvas.drawRRect(RRect.fromRectAndRadius(outer, corner), dark);

    // White ring.
    final ring = outer.deflate(moduleSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ring, Radius.circular(eyeSize * 0.18)),
      light,
    );

    // Center circle (matches Figma: rounded frame + circular pupil).
    final pupil = outer.deflate(moduleSize * 2.1);
    canvas.drawOval(pupil, dark);
  }

  @override
  bool shouldRepaint(covariant _RoundedTicketQrPainter oldDelegate) =>
      oldDelegate.data != data;
}
