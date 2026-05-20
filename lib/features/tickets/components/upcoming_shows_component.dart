import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class UpcomingShowsComponent extends StatelessWidget {
  const UpcomingShowsComponent({
    super.key,
    this.imageUrl = "https://picsum.photos/seed/dth-upcoming/960/540",
    this.title = "DTH Tradition Royalty Week",
    this.description =
        "De9jaspiriTalentHunt is back, and this time it's bigger and better than ever before! Prepare yourself for an exhilarating experience filled with music, culture, and unforgettable performances.",
    this.location = "Calabar Int'l Event Center, Calabar",
    this.dateTimeLabel = "9 Sept., 2026 02:30AM",
    this.showLocation = true,
    this.showDescription = true,
    this.showDivider = true,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String description;
  final String location;
  final String dateTimeLabel;

  /// When false (e.g. ticket strip), only the clock row is shown; pass a time
  /// string such as `02:30AM` in [dateTimeLabel].
  final bool showLocation;
  final bool showDescription;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 130,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  ColoredBox(color: AppColors.baseShimmer(context)),
              errorWidget: (_, __, ___) => ColoredBox(
                color: AppColors.baseShimmer(context),
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.tint15,
                ),
              ),
            ),
          ),
          Gap.h8,
          AppText.regular(
            title,
            color: AppColors.black,
            fontSize: 14,
            maxLines: 2,
            multiText: true,
          ),
          Gap.h4,
          if (showDescription) ...[
            AppText.regular(
              description,
              color: AppColors.black,
              fontSize: 12,
              maxLines: 2,
              multiText: true,
            ),
            Gap.h10,
          ],

          if (showLocation)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _MetaChip(
                    icon: SvgAssets.location,
                    text: location,
                    maxLines: 1,
                  ),
                ),
                Gap.w10,
                Expanded(
                  flex: 5,
                  child: _MetaChip(
                    icon: SvgAssets.clockOutline,
                    text: dateTimeLabel,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  SvgAssets.clockOutline,
                  width: 11,
                  height: 11,
                  colorFilter: ColorFilter.mode(
                    AppColors.blackTint20,
                    BlendMode.srcIn,
                  ),
                ),
                Gap.w4,
                AppText.regular(
                  dateTimeLabel,
                  color: AppColors.blackTint20,
                  fontSize: 10,
                  maxLines: 1,
                  multiText: false,
                ),
              ],
            ),
          if (showDivider) ...[
            Gap.h16,
            Container(
              height: 1,
              width: double.infinity,
              color: AppColors.greyTint25,
            ),
            Gap.h16,
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text, this.maxLines});

  final String icon;
  final String text;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          icon,
          width: 11,
          height: 11,
          colorFilter: ColorFilter.mode(AppColors.blackTint20, BlendMode.srcIn),
        ),
        Gap.w4,
        Expanded(
          child: AppText.regular(
            text,
            color: AppColors.blackTint20,
            fontSize: 10,
            maxLines: maxLines ?? 2,
            multiText: true,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
