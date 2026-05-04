import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/home/components/home_post_description.dart";
import "package:dth_v4/features/home/components/home_post_media.dart";
import "package:dth_v4/features/home/models/home_feed_models.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class HomePostCard extends StatelessWidget {
  const HomePostCard({super.key, required this.post});

  final HomePostItem post;

  static const Color _muted = Color(0xff8F8F8F);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SvgPicture.asset(SvgAssets.primaryLogo, height: 28, width: 28),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(SvgAssets.blackLogo, height: 16),
                      Gap.w2,
                      AppText.regular(
                        "with",
                        fontSize: 10,
                        color: AppColors.blackTint20,
                      ),
                      Gap.w2,
                      AppText.medium(
                        post.withName ?? "",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ],
                  ),

                  AppText.regular(post.timeAgo, fontSize: 10, color: _muted),
                ],
              ),
            ),
          ],
        ),
        // Gap.h8,
        if (post.description.isNotEmpty) ...[
          Gap.h12,
          HomePostDescription(text: post.description),
        ],
        Gap.h12,
        HomePostMedia(post: post),
        Gap.h12,
        Row(
          children: [
            _ActionChip(icon: SvgAssets.favoriteBorder, count: post.likeCount),
            Gap.w10,
            _ActionChip(
              icon: SvgAssets.messagesBorder,
              count: post.commentCount,
            ),
            Gap.w10,
            _ActionChip(icon: SvgAssets.share, count: post.shareCount),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.count});

  final String icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          icon,
          height: 14,
          width: 14,
          colorFilter: ColorFilter.mode(AppColors.blackTint20, BlendMode.srcIn),
        ),
        Gap.w4,
        AppText.medium('$count', fontSize: 12, color: AppColors.tint25),
      ],
    );
  }
}
