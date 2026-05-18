import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/tickets/components/show_purchased_ticket_card.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class ShowPurchasedTicketsSection extends StatelessWidget {
  const ShowPurchasedTicketsSection({
    super.key,
    required this.tickets,
    required this.descriptionFallback,
    this.onViewTickets,
  });

  final List<PurchasedTicket> tickets;
  final String descriptionFallback;
  final void Function(PurchasedTicket ticket)? onViewTickets;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.semiBold(
          "Purchased Tickets",
          fontSize: 14,
          color: AppColors.black,
          letterSpacing: -0.4,
        ),
        Gap.h12,
        for (var i = 0; i < tickets.length; i++) ...[
          if (i > 0) Gap.h12,
          ShowPurchasedTicketCard(
            ticket: tickets[i],
            descriptionFallback: descriptionFallback,
            onViewTickets: onViewTickets != null
                ? () => onViewTickets!(tickets[i])
                : null,
          ),
        ],
      ],
    );
  }
}
