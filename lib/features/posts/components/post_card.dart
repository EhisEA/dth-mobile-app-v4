import "package:dth_v4/core/utils/colors.dart";
import "package:dth_v4/features/posts/components/post_actions.dart";
import "package:dth_v4/features/posts/components/post_description.dart";
import "package:dth_v4/features/posts/components/post_header.dart";
import "package:dth_v4/features/posts/components/post_media.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.showDivider = true,
    this.compact = false,
  });

  static const double compactMediaHeight = 194;

  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final bool showDivider;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PosTimelinetHeader(post: post),
            if (post.description.isNotEmpty) ...[
              Gap.h8,
              AppText.regular(
                post.description.replaceAll("\n", " "),
                fontSize: 14,
                height: 1.4,
                maxLines: 2,
                color: const Color(0xff202020),
              ),
            ],
            Gap.h8,
            PostMedia(
              post: post,
              enableHero: false,
              height: compactMediaHeight,
            ),
            Gap.h8,
            PostActions(
              post: post,
              onLike: onLike,
              onComment: onComment,
              onShare: onShare,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosTimelinetHeader(post: post),
          if (post.description.isNotEmpty) ...[
            Gap.h12,
            PostDescription(
              text: post.description.replaceAll("\n", " "),
              shouldReadMoreAction: false,
            ),
          ],
          Gap.h12,
          PostMedia(post: post, enableHero: true),
          Gap.h10,
          PostActions(
            post: post,
            onLike: onLike,
            onComment: onComment,
            onShare: onShare,
          ),
          if (showDivider) ...[
            Gap.h8,
            Divider(thickness: 1.4, color: AppColors.greyTint30),
          ],
        ],
      ),
    );
  }
}
