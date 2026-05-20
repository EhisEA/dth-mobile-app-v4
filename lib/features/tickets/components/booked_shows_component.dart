import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/tickets/tickets.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class BookedShowsComponent extends StatelessWidget {
  const BookedShowsComponent({
    super.key,
    this.imageUrl = "https://picsum.photos/seed/dth-booked/400/400",
    this.title = "DTH Tradition Royalty Week",
    this.descriptionPreview =
        "De9jaspiriTalentHunt is back, and this time it's bigger and better than ever before! Prepare yourself for an exhilarating experience filled with music, culture, and unforgettable performances.",
    this.ticketQuantity = 4,
    this.scheduleLabel = "19 Sept., 2026 02:30AM",
    this.onReadMore,
    this.onViewTickets,
  });

  final String imageUrl;
  final String title;
  final String descriptionPreview;
  final int ticketQuantity;
  final String scheduleLabel;
  final VoidCallback? onReadMore;
  final VoidCallback? onViewTickets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onViewTickets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          ColoredBox(color: AppColors.baseShimmer(context)),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: AppColors.baseShimmer(context),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.tint15,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.medium(
                        title,
                        fontSize: 14,
                        color: AppColors.black,
                        maxLines: 2,
                        multiText: true,
                      ),
                      Gap.h10,
                      BookedShowDescription(
                        text: descriptionPreview,
                        onReadMore: onReadMore,
                      ),
                      Gap.h8,
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: AppTextStyle.regular.copyWith(
                                fontSize: 10,
                                color: AppColors.tint25,
                              ),
                              children: [
                                WidgetSpan(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: SvgPicture.asset(
                                      SvgAssets.clockOutline,
                                      width: 11,
                                      height: 11,
                                      colorFilter: ColorFilter.mode(
                                        AppColors.blackTint20,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),

                                TextSpan(
                                  text: scheduleLabel,
                                  style: AppTextStyle.regular.copyWith(
                                    fontSize: 10,
                                    color: AppColors.blackTint20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              style: AppTextStyle.regular.copyWith(
                                fontSize: 10,
                                color: AppColors.blackTint20,
                              ),
                              children: [
                                WidgetSpan(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: SvgPicture.asset(
                                      SvgAssets.ticket,
                                      width: 11,
                                      height: 11,
                                      colorFilter: ColorFilter.mode(
                                        AppColors.blackTint20,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),

                                TextSpan(text: "$ticketQuantity Tickets"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Gap.h16,
            // AppButton.onBorder(
            //   text: "View tickets",
            //   height: 48,
            //   radius: 100,
            //   fontSize: 14,
            //   borderColor: AppColors.primary,
            //   textColor: AppColors.primary,
            //   press: onViewTickets,
            // ),
            Gap.h20,
            Container(
              height: 1,
              width: double.infinity,
              color: AppColors.greyTint15,
            ),
          ],
        ),
      ),
    );
  }
}
