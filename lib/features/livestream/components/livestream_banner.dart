import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Compact home-feed banner for the currently active livestream. Visibility
/// is gated by the caller — render only when [activeLivestreamProvider] has
/// a non-null value. Tapping the banner mirrors the live-icon flow.
class LivestreamBanner extends StatelessWidget {
  const LivestreamBanner({
    super.key,
    required this.stream,
    required this.onTap,
  });

  final Livestream stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = stream.videoThumbnail?.trim() ?? "";
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.mainBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumb.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ShimmerBox(
                        baseColor: Color(0xff222222),
                        highlightColor: Color(0xff3A3A3A),
                      ),
                      errorWidget: (_, _, _) =>
                          const ColoredBox(color: Color(0xff222222)),
                    )
                  else
                    const ColoredBox(color: Color(0xff222222)),
                  // Subtle dim so the LIVE pill stays legible over bright frames.
                  Container(color: Colors.black.withValues(alpha: 0.2)),
                  const Positioned(top: 6, left: 6, child: _LivePill()),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.semiBold(
                      stream.title.isNotEmpty ? stream.title : "Live now",
                      fontSize: 14,
                      color: AppColors.white,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h4,
                    AppText.regular(
                      "Tap to join the stream",
                      fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.white.withValues(alpha: 0.7),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.redTint35,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          AppText.semiBold(
            "LIVE",
            fontSize: 10,
            color: AppColors.white,
            letterSpacing: 0.6,
          ),
        ],
      ),
    );
  }
}
