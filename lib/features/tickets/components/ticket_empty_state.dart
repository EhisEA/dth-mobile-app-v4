import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/empty_state.dart";
import "package:flutter/material.dart";

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
    return EmptyState(
      illustration: Image.asset(
        ImageAssets.ticketEmptyState,
        fit: BoxFit.contain,
      ),
      title: title,
      subtitle: subtitle,
      onRetry: onRetry,
    );
  }
}
