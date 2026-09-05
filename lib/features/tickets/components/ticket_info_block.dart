import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class TicketInfoBlock extends StatelessWidget {
  const TicketInfoBlock({
    super.key,
    required this.label,
    required this.value,
    this.maxLines = 3,
  });

  static const Color labelColor = Color(0xFF57688E);
  static const Color valueColor = Color(0xFF000000);

  final String label;
  final String value;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.cascadiaMonoBold(
          label,
          fontSize: 8,
          color: labelColor,
          letterSpacing: 1.8,
          height: 1,
        ),
        Gap.h4,
        AppText.semiBold(
          value,
          fontSize: 16,
          color: valueColor,
          letterSpacing: -0.2,
          maxLines: maxLines,
          multiText: true,
          height: 1.25,
        ),
      ],
    );
  }
}
