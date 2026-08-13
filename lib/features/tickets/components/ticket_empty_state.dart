import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Tickets-specific empty state using [ImageAssets.ticketEmptyState].
class TicketEmptyState extends StatelessWidget {
  const TicketEmptyState({
    super.key,
    this.title = "Tickets sales haven't opened yet.",
    this.subtitle =
        "Tickets aren't live yet — we're getting everything ready for an unforgettable DTH Season.",
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          ImageAssets.ticketEmptyState,
          fit: BoxFit.cover,
          width: context.width * 0.5,
          height: context.height * 0.3,
        ),

        AppText.medium(title, fontSize: 16, color: const Color(0xff202020)),
        Gap.h8,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: AppText.regular(
            subtitle,
            centered: true,
            fontSize: 14,
            color: AppColors.paleLavender,
          ),
        ),
        Gap.h24,
        if (onRetry != null) AppButton.primary(text: "Retry", press: onRetry),
      ],
    );
  }
}
