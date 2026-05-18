import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class ShowPurchasedTicketCard extends StatelessWidget {
  const ShowPurchasedTicketCard({
    super.key,
    required this.ticket,
    required this.descriptionFallback,
    this.onViewTickets,
  });

  final PurchasedTicket ticket;
  final String descriptionFallback;
  final VoidCallback? onViewTickets;

  @override
  Widget build(BuildContext context) {
    final description = ticket.description.trim().isNotEmpty
        ? ticket.description
        : descriptionFallback;
    final purchasedDate = ticket.datePurchased.trim();
    final ticketCount = ticket.count;
    final viewLabel = ticketCount > 0
        ? "View tickets ($ticketCount)"
        : "View tickets";

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        // borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: AppColors.greyTint30),
        image: DecorationImage(
          image: AssetImage(ImageAssets.ticketCardOutline),
          fit: BoxFit.fill,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TicketTypeIcon(url: ticket.iconUrl),
                Gap.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.medium(
                        ticket.displayTitle,
                        fontSize: 14,
                        color: AppColors.black,
                        letterSpacing: -0.4,
                        maxLines: 2,
                        multiText: true,
                      ),
                      if (description.isNotEmpty) ...[
                        Gap.h8,
                        AppText.regular(
                          description,
                          fontSize: 12,
                          color: AppColors.paleLavender,
                          letterSpacing: -0.2,
                          maxLines: 2,
                          multiText: true,
                          height: 1.35,
                        ),
                      ],
                      if (purchasedDate.isNotEmpty) ...[
                        Gap.h8,
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Date Purchased: ",
                                style: AppTextStyle.semiBold.copyWith(
                                  fontSize: 10,
                                  color: AppColors.tint25,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              TextSpan(
                                text: purchasedDate,
                                style: AppTextStyle.regular.copyWith(
                                  fontSize: 10,
                                  color: AppColors.tint25,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const _TicketPerforationDivider(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: AppButton.onBorder(
              text: viewLabel,
              height: 44,
              radius: 100,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              borderColor: AppColors.primary,
              textColor: AppColors.primary,
              press: onViewTickets,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketTypeIcon extends StatelessWidget {
  const _TicketTypeIcon({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
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

/// Dashed perforation with side notches, matching the ticket-stub design.
class _TicketPerforationDivider extends StatelessWidget {
  const _TicketPerforationDivider();

  static const double _notchRadius = 10;

  @override
  Widget build(BuildContext context) {
    final lineColor = AppColors.greyTint30;
    final bg = AppColors.white;

    return SizedBox(
      height: _notchRadius * 2,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: _notchRadius - 0.5,
            child: SizedBox(
              height: 1,
              child: CustomPaint(painter: _DashedLinePainter(color: lineColor)),
            ),
          ),
          Positioned(
            left: -_notchRadius,
            child: Container(
              width: _notchRadius * 2,
              height: _notchRadius * 2,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: -_notchRadius,
            child: Container(
              width: _notchRadius * 2,
              height: _notchRadius * 2,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 5.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
