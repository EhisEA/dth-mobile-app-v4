import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/components/comment_composer.dart";
import "package:dth_v4/features/posts/components/comment_sort_header.dart";
import "package:dth_v4/features/posts/components/comment_tile.dart";
import "package:dth_v4/features/posts/components/like_chip.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/view_model/comment_thread_view_model.dart";
import "package:dth_v4/features/posts/view_model/comments_cache.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class CommentThreadView extends ConsumerWidget {
  const CommentThreadView({super.key, required this.commentUid});

  static const String path = NavigatorRoutes.commentThread;

  final String commentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(commentThreadViewModelProvider(commentUid));
    // Cache owns Comment state; watching it here means a like-toggle on the
    // post detail screen (or anywhere else) rebuilds this view.
    final cache = ref.watch(commentsCacheProvider);
    final parent = cache.get(commentUid);
    final replies = vm.replyUids
        .map(cache.get)
        .whereType<Comment>()
        .toList(growable: false);

    return Scaffold(
      appBar: const DthAppBar(backgroundColor: Colors.white, title: "Comments"),
      backgroundColor: const Color(0xffFCFCFC),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => vm.refresh(),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                    unawaited(vm.loadMore());
                  }
                  return false;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (parent != null)
                      _ParentCommentBlock(comment: parent, vm: vm),
                    Gap.h16,
                    Container(height: 1, color: const Color(0xffEFEFEF)),
                    Gap.h16,
                    CommentSortHeader(
                      title: "Replies",
                      count: parent?.replyCount ?? replies.length,
                      sort: vm.sort,
                      onSortChanged: vm.setSort,
                    ),
                    Gap.h16,
                    if (vm.repliesLoading && replies.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      )
                    else if (vm.repliesError != null && replies.isEmpty)
                      _RepliesErrorState(
                        message: vm.repliesError!.message,
                        onRetry: vm.retry,
                      )
                    else if (replies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: AppText.regular(
                          "No replies yet. Be the first.",
                          fontSize: 12,
                          color: AppColors.blackTint20,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      ...replies.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: CommentTile(
                            comment: r,
                            
                            onLike: () => vm.toggleReplyLike(r),
                          ),
                        ),
                      ),
                      if (vm.loadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          CommentComposer(
            replyToName: parent?.authorName,
            submitting: vm.submitting,
            onSubmit: vm.submit,
          ),
        ],
      ),
    );
  }
}

class _ParentCommentBlock extends StatelessWidget {
  const _ParentCommentBlock({required this.comment, required this.vm});

  final Comment comment;
  final CommentThreadViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LargeAvatar(name: comment.authorName, url: comment.avatarUrl),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: AppText.semiBold(
                          comment.authorName.isEmpty
                              ? "User"
                              : comment.authorName,
                          fontSize: 14,
                          color: AppColors.mainBlack,
                          maxLines: 1,
                        ),
                      ),
                      Gap.w8,
                      AppText.regular(
                        comment.timeAgo,
                        fontSize: 11,
                        color: AppColors.blackTint20,
                      ),
                    ],
                  ),
                  if (comment.username != null) ...[
                    Gap.h2,
                    AppText.regular(
                      "@${comment.username}",
                      fontSize: 12,
                      color: AppColors.blackTint20,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        Gap.h12,
        AppText.regular(
          comment.body,
          fontSize: 13,
          height: 1.5,
          color: const Color(0xff202020),
        ),
        Gap.h12,
        AppText.regular(
          _postedLine(comment),
          fontSize: 11,
          color: AppColors.blackTint20,
        ),
        Gap.h12,
        _ParentActions(comment: comment, onLike: vm.toggleParentLike),
      ],
    );
  }

  String _postedLine(Comment c) {
    final parts = <String>["Posted ${c.timeAgo}"];
    if (c.viewCount > 0) {
      parts.add(_formatCount(c.viewCount));
    }
    return parts.join(" · ");
  }

  String _formatCount(int n) => "${formatCount(n)} views";
}

class _ParentActions extends StatelessWidget {
  const _ParentActions({required this.comment, required this.onLike});

  final Comment comment;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              LikeChip(
                padding: EdgeInsets.fromLTRB(12, 10, 10, 10),

                liked: comment.viewerReacted,
                count: comment.likeCount,
                onTap: onLike,
              ),
              Container(width: 1, height: 14, color: const Color(0xffEBEBEB)),
              _ActionChip(
                icon: SvgAssets.messagesBorder,
                count: comment.replyCount,
                padding: EdgeInsets.fromLTRB(10, 6, 12, 6),
                // onTap: onComment,
              ),
            ],
          ),
        ),
        Gap.w10,
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _ActionChip(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            icon: SvgAssets.share,
            count: comment.shareCount,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.count, this.padding});

  final String icon;
  final int count;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                AppColors.blackTint20,
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

class _RepliesErrorState extends StatelessWidget {
  const _RepliesErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          AppText.regular(
            message,
            fontSize: 12,
            color: AppColors.blackTint20,
            textAlign: TextAlign.center,
          ),
          Gap.h12,
          AppButton.primary(text: "Retry", height: 40, press: onRetry),
        ],
      ),
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? "?"
        : name.trim().characters.first.toUpperCase();
    final placeholder = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.baseShimmer(context),
      ),
      child: AppText.semiBold(
        initial,
        fontSize: 14,
        color: AppColors.blackTint20,
      ),
    );
    final src = url?.trim();
    if (src == null || src.isEmpty) return placeholder;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: src,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}
