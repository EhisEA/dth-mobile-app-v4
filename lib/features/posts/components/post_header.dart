import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class PosTimelinetHeader extends StatelessWidget {
  const PosTimelinetHeader({super.key, required this.post});

  final Post post;

  static const Color _muted = Color(0xff8F8F8F);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(SvgAssets.primaryLogo, height: 28, width: 28),
            Gap.w12,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.medium(
                    post.title,
                    fontSize: 16,
                    maxLines: 1,
                    color: AppColors.black,
                  ),
                  // Gap.h2,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppText.regular(
                        "Featuring",
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.blackTint20,
                      ),
                      Gap.w2,
                      Flexible(
                        child: AppText.medium(
                          post.subtitle ?? "General",
                          fontSize: 12,
                          maxLines: 1,
                          color: AppColors.black,
                        ),
                      ),
                      Gap.w6,
                      AppText.regular(
                        post.createdAt ?? "",
                        fontSize: 12,
                        color: _muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PostDetailsHeader extends StatelessWidget {
  const PostDetailsHeader({super.key, required this.post});

  final Post post;

  static const Color _muted = Color(0xff8F8F8F);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.medium(
          post.title,
          color: AppColors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        Gap.h4,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(SvgAssets.primaryLogo, height: 14, width: 14),
            Gap.w6,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    SvgAssets.blackLogo,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  Gap.w2,
                  AppText.medium(
                    "Featuring",
                    fontSize: 12,
                    color: AppColors.blackTint20,
                  ),
                  Gap.w2,
                  Flexible(
                    child: AppText.semiBold(
                      post.subtitle ?? "General" * 3,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                      maxLines: 1,
                    ),
                  ),
                  Gap.w4,
                  AppText.medium(
                    post.createdAt ?? "",
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.blackTint20,
                    maxLines: 1,
                  ),
                  if (post.viewCount > 0) ...[
                    Gap.w4,
                    AppText.medium(
                      "${post.viewCount} views",
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.blackTint20,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
