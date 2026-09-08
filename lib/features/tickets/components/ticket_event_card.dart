import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/tickets/view_model/ticket_home_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

enum TicketEventCardMode { upcoming, purchased }

class TicketEventCard extends StatelessWidget {
  const TicketEventCard({
    super.key,
    required this.event,
    required this.mode,
    this.onTap,
    this.onBuyTicket,
  });

  final EventListItem event;
  final TicketEventCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onBuyTicket;

  factory TicketEventCard.fromTab({
    Key? key,
    required EventListItem event,
    required TicketHomeTab tab,
    VoidCallback? onTap,
    VoidCallback? onBuyTicket,
  }) {
    return TicketEventCard(
      key: key,
      event: event,
      mode: tab == TicketHomeTab.upcoming
          ? TicketEventCardMode.upcoming
          : TicketEventCardMode.purchased,
      onTap: onTap,
      onBuyTicket: onBuyTicket,
    );
  }

  static const double _heroHeight = 225;

  @override
  Widget build(BuildContext context) {
    final isPurchased = mode == TicketEventCardMode.purchased;
    final ownedCount =
        event.ticketsOwned ?? int.tryParse(event.ticketsCount) ?? 0;
    // Left null when the API omits `tickets_left` — the pill is hidden rather
    // than defaulting to 0, which would read as "sold out" next to an active
    // Buy button.
    final ticketsLeft = event.ticketsLeft;
    final description = event.shortDescription.trim();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: _heroHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: event.displayImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        ColoredBox(color: AppColors.baseShimmer(context)),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: AppColors.baseShimmer(context),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.tint15,
                        size: 36,
                      ),
                    ),
                  ),
                  if (isPurchased)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _OwnedBadge(count: ownedCount),
                    ),
                ],
              ),
            ),
          ),
          Gap.h16,
          AppText.medium(
            event.title,
            fontSize: 16,
            color: const Color(0xff202020),
            maxLines: 2,
            height: 1.2,
            multiText: true,
          ),
          if (event.date.isNotEmpty || event.time.isNotEmpty) ...[
            Gap.h8,
            Row(
              children: [
                if (event.date.isNotEmpty)
                  Flexible(
                    child: _MetaItem(
                      icon: SvgAssets.calender2,
                      label: event.date,
                    ),
                  ),
                if (event.date.isNotEmpty && event.time.isNotEmpty) Gap.w12,
                if (event.time.isNotEmpty)
                  Flexible(
                    child: _MetaItem(
                      icon: SvgAssets.clockOutline,
                      label: event.time,
                    ),
                  ),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            Gap.h8,
            AppText.regular(
              description,
              fontSize: 14,
              color: AppColors.tint25,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              height: 1.2,
              multiText: true,
            ),
          ],
          if (!isPurchased) ...[
            Gap.h14,
            Row(
              children: [
                if (ticketsLeft != null) ...[
                  Expanded(child: _AvailabilityPill(count: ticketsLeft)),
                  Gap.w12,
                ],
                Expanded(
                  child: AppButton.primary(
                    text: "Buy ticket now",
                    height: 52,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    radius: 100,
                    press: onBuyTicket ?? onTap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnedBadge extends StatelessWidget {
  const _OwnedBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(ImageAssets.ticket, width: 16, height: 16),
          Gap.w4,
          AppText.medium(
            "$count owned",
            fontSize: 12,
            height: 1.2,
            color: AppColors.tertiary60,
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImageAssets.availableTicketBg),
          fit: BoxFit.cover,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.medium(
            "$count available",
            fontSize: 14,
            color: AppColors.black,
            height: 0,
          ),
          Gap.w8,
          Image.asset(ImageAssets.ticket, width: 24, height: 24),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          icon,
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(
            const Color(0xff001119),
            BlendMode.srcIn,
          ),
        ),
        Gap.w6,
        Flexible(
          child: AppText.regular(
            label,
            fontSize: 13,
            color: AppColors.tint25,
            maxLines: 1,
            height: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
