import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/double_extension.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/tickets/components/purchase_ticket_quantity_count_widget.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class PurchaseTicketItem extends StatelessWidget {
  const PurchaseTicketItem({
    super.key,
    required this.ticket,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onQuantityChanged,
  });

  final AvailableTicket ticket;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final priceLabel = "₦${ticket.amountValue.toMoneyWholeNumber()}";
    final canIncrement =
        ticket.availableTickets <= 0 || quantity < ticket.availableTickets;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TicketIcon(url: ticket.iconUrl),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.medium(
                  ticket.label,
                  fontSize: 14,
                  color: AppColors.black,
                  letterSpacing: -0.4,
                  maxLines: 1,
                ),
                Gap.h4,
                AppText.regular(
                  ticket.description,
                  fontSize: 10,
                  color: AppColors.paleLavender,
                  letterSpacing: -0.2,
                  maxLines: 2,
                  multiText: true,
                ),
                Gap.h4,
                AppText.regular(
                  priceLabel,
                  fontSize: 12,
                  color: AppColors.black,
                  letterSpacing: -0.2,
                ),
              ],
            ),
          ),
          Gap.w8,
          PurchaseTicketCountWidget(
            quantity: quantity,
            maxQuantity: ticket.availableTickets,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            onQuantityChanged: onQuantityChanged,
            canIncrement: canIncrement,
          ),
        ],
      ),
    );
  }
}

class _TicketIcon extends StatelessWidget {
  const _TicketIcon({required this.url});

  final String url;

  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.greyTint15,
        border: Border.all(color: AppColors.greyTint30),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return _placeholder();
    }

    final path =
        Uri.tryParse(trimmed)?.path.toLowerCase() ?? trimmed.toLowerCase();
    if (path.endsWith(".svg")) {
      return SvgPicture.network(
        trimmed,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      fit: BoxFit.cover,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.greyTint15,
      child: Icon(
        Icons.confirmation_number_outlined,
        size: 22,
        color: AppColors.blackTint20,
      ),
    );
  }
}
