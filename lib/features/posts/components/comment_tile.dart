import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/components/like_chip.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.onTap,
    this.onLike,
    this.showReplyChip = false,
  });

  final Comment comment;

  /// Tapping anywhere on the tile. In the post-detail comments list this
  /// navigates to the thread screen; in the thread screen replies pass null.
  final VoidCallback? onTap;

  final VoidCallback? onLike;

  /// Render the reply-count chip alongside the heart. False on replies inside
  /// the thread screen (replies don't have nested replies in this design).
  final bool showReplyChip;

  @override
  Widget build(BuildContext context) {
    final tile = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _Avatar(name: comment.authorName, url: comment.avatarUrl),
        Gap.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: AppText.medium(
                      comment.authorName.isEmpty ? "User" : comment.authorName,
                      fontSize: 12,
                      color: AppColors.black,
                      maxLines: 1,
                    ),
                  ),
                  Gap.w8,
                  AppText.regular(
                    comment.timeAgo,
                    fontSize: 10,
                    color: AppColors.blackTint20,
                  ),
                ],
              ),
              Gap.h4,
              AppText.regular(
                comment.body,
                fontSize: 12,
                height: 1.4,
                color: AppColors.mainBlack,
              ),
              Gap.h8,
              Row(
                children: [
                  if (showReplyChip) ...[
                    LikeChip(
                      // Key by uid so the animation State stays paired with
                      // its comment even if the list reorders — otherwise
                      // _colorTween can be reused across a different reply
                      // and lock the heart in the wrong colour.
                      key: ValueKey("like-${comment.uid}"),
                      padding: const EdgeInsets.all(8.0),
                      liked: comment.viewerReacted,
                      count: comment.likeCount,
                      onTap: onLike,
                      iconSize: 12,
                      fontSize: 11,
                    ),
                    // Gap.w16,
                    _Chip(
                      icon: SvgAssets.messagesBorder,
                      count: comment.replyCount,
                      onTap: onTap,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (!showReplyChip)
          LikeChip(
            key: ValueKey("like-${comment.uid}"),
            padding: const EdgeInsets.all(8.0),
            liked: comment.viewerReacted,
            count: comment.likeCount,
            onTap: onLike,
            iconSize: 12,
            fontSize: 11,
          ),
      ],
    );
    if (onTap == null) return tile;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: tile,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? "?"
        : name.trim().characters.first.toUpperCase();
    final placeholder = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.baseShimmer(context),
      ),
      child: AppText.semiBold(
        initial,
        fontSize: 12,
        color: AppColors.blackTint20,
      ),
    );
    final src = url?.trim();
    if (src == null || src.isEmpty) return placeholder;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: src,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.count, this.onTap});

  final String icon;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              height: 12,
              width: 12,
              colorFilter: ColorFilter.mode(
                AppColors.blackTint20,
                BlendMode.srcIn,
              ),
            ),
            Gap.w4,
            AppText.medium('$count', fontSize: 11, color: AppColors.tint25),
          ],
        ),
      ),
    );
  }
}
