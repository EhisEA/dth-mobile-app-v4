import "package:dth_v4/features/posts/components/post_actions.dart";
import "package:dth_v4/features/posts/components/post_description.dart";
import "package:dth_v4/features/posts/components/post_header.dart";
import "package:dth_v4/features/posts/components/post_media.dart";
import "package:dth_v4/features/posts/models/post.dart";
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
  });

  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosTimelinetHeader(post: post),
          if (post.description.isNotEmpty) ...[
            Gap.h12,
            PostDescription(text: post.description),
          ],
          Gap.h12,
          PostMedia(post: post),
          Gap.h4,
          PostActions(
            post: post,
            showContainer: false,
            onLike: onLike,
            onComment: onComment,
            onShare: onShare,
          ),
        ],
      ),
    );
  }
}
