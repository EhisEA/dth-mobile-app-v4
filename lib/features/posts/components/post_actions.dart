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
    this.showContainer = true,
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
          // padding: showContainer
          //     ? const EdgeInsets.symmetric(vertical: 10, horizontal: 12)
          //     : null,
          decoration: BoxDecoration(
            color: showContainer ? const Color(0xFFF7F7F7) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              LikeChip(
                padding: EdgeInsets.fromLTRB(
                  showContainer ? 12 : 0,
                  10,
                  10,
                  10,
                ),
                liked: post.viewerReacted,
                count: post.likeCount,
                onTap: onLike,
              ),
              if (showContainer)
                Container(width: 1, height: 14, color: const Color(0xffEBEBEB)),
              _ActionChip(
                icon: SvgAssets.messagesBorder,
                count: post.commentCount,
                padding: EdgeInsets.fromLTRB(10, 6, 12, 6),
                onTap: onComment,
              ),
            ],
          ),
        ),
        if (showContainer) Gap.w10,
        Container(
          decoration: BoxDecoration(
            color: showContainer ? const Color(0xFFF7F7F7) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _ActionChip(
            padding: showContainer
                ? const EdgeInsets.symmetric(vertical: 10, horizontal: 16)
                : const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
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
    this.padding,
    this.tint,
    this.onTap,
  });

  final String icon;
  final EdgeInsets? padding;
  final int count;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: padding,
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
      ),
    );
  }
}
