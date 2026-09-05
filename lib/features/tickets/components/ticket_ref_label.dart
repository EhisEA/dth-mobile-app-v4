import "package:dth_v4/features/tickets/components/ticket_barcode.dart";
import "package:flutter/material.dart";

class TicketRefLabel extends StatelessWidget {
  const TicketRefLabel({super.key, required this.reference});

  final String reference;

  static const _style = TextStyle(
    fontSize: 9,
    color: Color(0xBF000000),
    height: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    final chars = reference.split("");
    return SizedBox(
      width: TicketBarcode.width,
      child: Row(
        children: [
          const Text("REF:", style: _style),
          if (chars.isNotEmpty) ...[
            const SizedBox(width: 4),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [for (final char in chars) Text(char, style: _style)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
