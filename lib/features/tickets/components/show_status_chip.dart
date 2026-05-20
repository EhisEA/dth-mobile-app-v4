import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";

class ShowStatusChip extends StatelessWidget {
  const ShowStatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffF1F3FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AppText.regular(
        label,
        fontSize: 10,
        color: const Color(0xff284FEB),
        letterSpacing: -0.25,
      ),
    );
  }
}
