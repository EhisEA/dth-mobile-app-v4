import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";

class ShowBuyTicket extends StatelessWidget {
  const ShowBuyTicket({
    super.key,
    this.mainLabel = "Buy ticket now",
    this.availabilityLabel,
    this.onPressed,
  });

  final String mainLabel;
  final String? availabilityLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      height: 52,
      text: mainLabel,
      subtitle: availabilityLabel,
      subtitleFontSize: 10,
      fontWeight: FontWeight.w500,
      subtitleColor: AppColors.white.withValues(alpha: 0.92),
      press: onPressed,
    );
  }
}
