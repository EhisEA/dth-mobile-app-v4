import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/components/comment_composer.dart";
import "package:dth_v4/features/posts/components/comment_sort_header.dart";
import "package:dth_v4/features/posts/components/comment_tile.dart";
import "package:dth_v4/features/posts/components/post_actions.dart";
import "package:dth_v4/features/posts/components/post_detail_skeleton.dart";
import "package:dth_v4/features/posts/components/post_header.dart";
import "package:dth_v4/features/posts/components/post_media.dart";
import "package:dth_v4/features/posts/components/youtube_player_embed.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/features/posts/view_model/comments_cache.dart";
import "package:dth_v4/features/posts/view_model/post_detail_view_model.dart";
import "package:dth_v4/features/posts/views/comment_thread_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class PostDetailView extends ConsumerWidget {
  const PostDetailView({super.key, required this.uid});

  static const String path = NavigatorRoutes.postDetail;

  final String uid;

  void _showComingSoon(String label) {
    DthFlushBar.instance.showGeneric(
      message: "$label is coming soon.",
      title: "Heads up",
    );
  }

  void _openThread(String commentUid) {
    MobileNavigationService.instance.push(
      CommentThreadView.path,
      extra: {RoutingArgumentKey.commentUid: commentUid},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(postDetailViewModelProvider(uid));
    final post = vm.post;
    // Cache owns Comment state; watch it so a like-toggle in the thread
    // screen rebuilds the comments list here automatically.
    final commentsCache = ref.watch(commentsCacheProvider);
    final comments = vm.commentUids
        .map(commentsCache.get)
        .whereType<Comment>()
        .toList(growable: false);

    return Scaffold(
      appBar: DthAppBar(backgroundColor: Colors.white),
      backgroundColor: Color(0xffFCFCFC),
      body: vm.baseState.when(
        busy: () => const PostDetailSkeleton(),
        error: (Failure failure) =>
            _ErrorState(message: failure.message, onRetry: () => vm.refresh()),
        idle: () {
          if (post == null) {
            return const PostDetailSkeleton();
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => vm.refresh(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.pixels >=
                          n.metrics.maxScrollExtent - 400) {
                        unawaited(vm.loadMoreComments());
                      }
                      return false;
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        _PostBlock(
                          post: post,
                          onLike: vm.togglePostLike,
                          onShare: () => _showComingSoon("Share"),
                        ),
                        Gap.h24,
                        _CommentsSection(
                          vm: vm,
                          comments: comments,
                          onOpenThread: _openThread,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              CommentComposer(
                submitting: vm.submitting,
                onSubmit: vm.submit,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PostBlock extends StatefulWidget {
  const _PostBlock({
    required this.post,
    required this.onLike,
    required this.onShare,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onShare;

  @override
  State<_PostBlock> createState() => _PostBlockState();
}

class _PostBlockState extends State<_PostBlock> {
  late bool _playing;

  @override
  void initState() {
    super.initState();
    _playing = _canPlayInline(widget.post);
  }

  @override
  void didUpdateWidget(covariant _PostBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.uid != widget.post.uid) {
      _playing = _canPlayInline(widget.post);
    }
  }

  bool _canPlayInline(Post p) {
    final v = p.video;
    return p.isVideo && v != null && v.isYoutube && v.isPlayable;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final video = post.video;
    final canPlayInline = _canPlayInline(post);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_playing && canPlayInline)
          YoutubePlayerEmbed(embedUrl: video!.videoUrl!)
        else
          PostMedia(
            post: post,
            onPlayVideo: canPlayInline
                ? () => setState(() => _playing = true)
                : null,
          ),
        Gap.h16,
        PostHeader(post: post),
        if (post.description.isNotEmpty) ...[
          Gap.h12,
          AppText.regular(
            post.description,
            fontSize: 12,
            height: 1.45,
            color: Color(0xff202020),
          ),
        ],
        Gap.h18,
        PostActions(
          post: post,
          onLike: widget.onLike,
          onComment: () {},
          onShare: widget.onShare,
        ),
      ],
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.vm,
    required this.comments,
    required this.onOpenThread,
  });

  final PostDetailViewModel vm;
  final List<Comment> comments;
  final void Function(String commentUid) onOpenThread;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommentSortHeader(
          title: "Comments",
          count: vm.post?.commentCount ?? comments.length,
          sort: vm.sort,
          onSortChanged: vm.setSort,
        ),
        Gap.h16,
        if (vm.commentsLoading && comments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator.adaptive(),
            ),
          )
        else if (vm.commentsError != null && comments.isEmpty)
          _CommentsErrorState(
            message: vm.commentsError!.message,
            onRetry: () => vm.retryLoadComments(),
          )
        else if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: AppText.regular(
              "Be the first to drop a banger.",
              fontSize: 12,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          ...comments.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: CommentTile(
                comment: c,
                onTap: () => onOpenThread(c.uid),
                onLike: () => vm.toggleCommentLike(c),
                showReplyChip: true,
              ),
            ),
          ),
          if (vm.loadingMoreComments)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
        ],
      ],
    );
  }
}

class _CommentsErrorState extends StatelessWidget {
  const _CommentsErrorState({required this.message, required this.onRetry});

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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        shrinkWrap: true,
        children: [
          AppText.semiBold(
            "Could not load post",
            fontSize: 16,
            color: AppColors.mainBlack,
            textAlign: TextAlign.center,
          ),
          Gap.h12,
          AppText.regular(
            message,
            fontSize: 14,
            color: AppColors.blackTint20,
            textAlign: TextAlign.center,
          ),
          Gap.h24,
          Center(
            child: AppButton.primary(text: "Retry", height: 48, press: onRetry),
          ),
        ],
      ),
    );
  }
}
