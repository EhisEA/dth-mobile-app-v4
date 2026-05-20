import 'package:cached_network_image/cached_network_image.dart';
import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/features/posts/components/like_chip.dart';
import 'package:dth_v4/features/posts/models/comment.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.onLike,
    this.parent = true,
  });

  final Comment comment;

  /// Whether the comment is a parent comment.
  final bool parent;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final avatar = comment.avatarUrl?.trim() ?? "";
    final initial = comment.authorName.isNotEmpty
        ? comment.authorName[0].toUpperCase()
        : "?";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.baseShimmer(context),
          backgroundImage: avatar.isNotEmpty
              ? CachedNetworkImageProvider(avatar)
              : null,
          child: avatar.isNotEmpty
              ? null
              : AppText.regular(
                  initial,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.paleLavender,
                ),
        ),
        Gap.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppText.medium(
                    comment.authorName,
                    fontSize: 14,
                    color: Color(0xff202020),
                  ),
                  Gap.w4,
                  AppText.regular(
                    comment.timeAgo,
                    fontSize: 10,
                    color: AppColors.tint15,
                  ),
                ],
              ),
              // Gap.h8,
              AppText.regular(
                comment.body,
                fontSize: 12,
                color: Color(0xff202020),
                height: 1.35,
              ),
              if (parent) ...[
                Gap.h8,
                Row(
                  children: [
                    LikeChip(
                      liked: comment.viewerReacted,
                      count: comment.likeCount,
                      onTap: onLike,
                      iconSize: 16,
                      fontSize: 12,
                      inactiveColor: AppColors.blackTint20,
                      countColor: AppColors.blackTint20,
                    ),
                    Gap.w8,
                    SvgPicture.asset(
                      SvgAssets.messagesBorder,
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        AppColors.blackTint20,
                        BlendMode.srcIn,
                      ),
                    ),
                    Gap.w4,
                    AppText.medium(
                      formatCount(comment.replyCount),
                      fontSize: 12,
                      color: AppColors.blackTint20,
                    ),
                    Gap.w8,
                    SvgPicture.asset(
                      SvgAssets.sendBorder,
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        AppColors.blackTint20,
                        BlendMode.srcIn,
                      ),
                    ),
                    Gap.w4,
                    AppText.medium(
                      formatCount(comment.shareCount),
                      fontSize: 12,
                      color: AppColors.blackTint20,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        parent
            ? const SizedBox.shrink()
            : LikeChip(
                liked: comment.viewerReacted,
                count: comment.likeCount,
                onTap: onLike,
                iconSize: 16,
                fontSize: 12,
                inactiveColor: AppColors.blackTint20,
                countColor: AppColors.blackTint20,
              ),
      ],
    );
  }
}
