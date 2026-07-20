import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/features/posts/components/post_card.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class PinnedPostsBar extends StatelessWidget {
  const PinnedPostsBar({
    super.key,
    required this.posts,
    required this.onTap,
    required this.onLike,
    required this.onShare,
  });

  final List<Post> posts;
  final ValueChanged<Post> onTap;
  final ValueChanged<String> onLike;
  final ValueChanged<Post> onShare;

  static const double _cardWidthFactor = 0.9;
  static const double _cardPadding = 12;
  static const double _headerHeight = 38;
  static const double _sectionGap = 8;
  static const double _descriptionHeight = 40;
  static const double _actionsHeight = 28;

  /// Fixed height for the horizontal list — matches compact card layout.
  static const double barHeight =
      _cardPadding * 2 +
      _headerHeight +
      _sectionGap +
      _descriptionHeight +
      _sectionGap +
      PostCard.compactMediaHeight +
      _sectionGap +
      _actionsHeight;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();

    final cardWidth = MediaQuery.sizeOf(context).width * _cardWidthFactor;

    return SizedBox(
      height: barHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        separatorBuilder: (_, __) => Gap.w12,
        itemBuilder: (context, index) {
          final post = posts[index];
          return SizedBox(
            width: cardWidth,
            height: barHeight,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyTint35),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(_cardPadding),
              child: PostCard(
                post: post,
                compact: true,
                showDivider: false,
                onTap: () => onTap(post),
                onLike: () => onLike(post.uid),
                onShare: () => onShare(post),
              ),
            ),
          );
        },
      ),
    );
  }
}
