import "package:barcode/barcode.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

class TicketBarcode extends StatelessWidget {
  const TicketBarcode({super.key, required this.data});

  final String data;

  static const double width = 75;
  static const double height = 14;

  static final Barcode _barcode = Barcode.code128();

  @override
  Widget build(BuildContext context) {
    final value = data.trim().isNotEmpty ? data.trim() : "0";

    try {
      final svg = _barcode.toSvg(
        value,
        width: width,
        height: height,
        drawText: false,
        color: 0x000000,
      );
      return SizedBox(
        width: width,
        height: height,
        child: SvgPicture.string(svg, fit: BoxFit.fill),
      );
    } catch (_) {
      return const SizedBox(width: width, height: height);
    }
  }
}
