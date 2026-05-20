import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/components/like_chip.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class PostActions extends StatelessWidget {
  const PostActions({
    super.key,
    required this.post,
    this.onLike,
    this.showContainer = false,
    this.onComment,
    this.onShare,
  });

  final bool showContainer;
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: showContainer
              ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
              : null,
          decoration: BoxDecoration(
            color: showContainer ? const Color(0xFFF7F7F7) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              LikeChip(
                liked: post.viewerReacted,
                count: post.likeCount,
                onTap: onLike,
              ),
              if (showContainer) ...[
                Gap.w8,

                Container(width: 1, height: 14, color: const Color(0xffEBEBEB)),
              ],
              if (showContainer) Gap.w8 else Gap.w10,

              _ActionChip(
                icon: SvgAssets.messagesBorder,
                count: post.commentCount,
                onTap: onComment,
              ),
            ],
          ),
        ),
        if (showContainer) Gap.w8 else Gap.w10,
        Container(
          padding: showContainer
              ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
              : null,
          decoration: BoxDecoration(
            color: showContainer ? const Color(0xFFF7F7F7) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _ActionChip(
            icon: SvgAssets.share,
            count: post.shareCount,
            tint: const Color(0xff454545),
            onTap: onShare,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.count,
    this.tint,
    this.onTap,
  });

  final String icon;
  final int count;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            height: 14,
            width: 14,
            colorFilter: ColorFilter.mode(
              tint ?? AppColors.blackTint20,
              BlendMode.srcIn,
            ),
          ),
          Gap.w4,
          AppText.medium(
            formatCount(count),
            fontSize: 12,
            color: AppColors.tint25,
          ),
        ],
      ),
    );
  }
}
