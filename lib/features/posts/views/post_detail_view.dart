import "dart:async";
import "dart:ui";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/components/comment_composer.dart";
import "package:dth_v4/features/posts/components/comment_sort_header.dart";
import "package:dth_v4/features/posts/components/comment_tile.dart";
import "package:dth_v4/features/posts/components/post_actions.dart";
import "package:dth_v4/features/posts/components/post_detail_skeleton.dart";
import "package:dth_v4/features/posts/components/post_header.dart";
import "package:dth_v4/features/posts/components/post_hero_image.dart";
import "package:dth_v4/features/posts/components/post_media.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/features/posts/view_model/comments_cache.dart";
import "package:dth_v4/features/posts/view_model/post_detail_view_model.dart";
import "package:dth_v4/features/posts/views/comment_thread_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:youtube_player_flutter/youtube_player_flutter.dart";

class PostDetailView extends ConsumerStatefulWidget {
  const PostDetailView({super.key, required this.uid});

  static const String path = NavigatorRoutes.postDetail;

  final String uid;

  @override
  ConsumerState<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends ConsumerState<PostDetailView> {
  // The YouTube player controller is owned here (not inside the embed widget)
  // so we can wrap the whole Scaffold in YoutubePlayerBuilder — which is the
  // only place fullscreen rotation/expansion can actually take over the
  // entire screen.
  YoutubePlayerController? _ytController;
  String? _ytVideoId;
  // Until the IFrame player calls back as "ready", we overlay a black mask
  // with our own spinner — otherwise YouTube's own iframe loading chrome
  // (logo + branding) flashes for a beat before our control bar takes over.
  bool _ytReady = false;

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  /// Keep [_ytController] in sync with [post]'s video URL. Called inline from
  /// build — only mutates fields, no setState, so the current build reads the
  /// updated controller immediately.
  void _syncController(Post post) {
    final url = post.isVideo && (post.video?.isYoutube ?? false)
        ? post.video?.videoUrl
        : null;
    final newId = url == null ? null : YoutubePlayer.convertUrlToId(url);
    if (newId == _ytVideoId) return;
    _ytController?.dispose();
    _ytVideoId = newId;
    _ytReady = false;
    _ytController = newId == null
        ? null
        : YoutubePlayerController(
            initialVideoId: newId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: true,
              enableCaption: false,
              forceHD: false,
            ),
          );
  }

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
  Widget build(BuildContext context) {
    final vm = ref.watch(postDetailViewModelProvider(widget.uid));
    final post = vm.post;
    if (post != null) _syncController(post);

    // Cache owns Comment state; watch it so a like-toggle in the thread
    // screen rebuilds the comments list here automatically.
    final commentsCache = ref.watch(commentsCacheProvider);
    final comments = vm.commentUids
        .map(commentsCache.get)
        .whereType<Comment>()
        .toList(growable: false);

    final isHero = post != null && !post.isVideo && post.imageUrls.isNotEmpty;

    Widget buildScaffold(Widget? mediaSlot) => Scaffold(
      extendBodyBehindAppBar: isHero,
      appBar: isHero
          ? const _TransparentBackAppBar()
          : DthAppBar(backgroundColor: Colors.white),
      backgroundColor: const Color(0xffFCFCFC),
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
                      if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                        unawaited(vm.loadMoreComments());
                      }
                      return false;
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [
                        if (isHero) PostHeroImage(urls: post.imageUrls),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            isHero ? 16 : 12,
                            16,
                            0,
                          ),
                          child: _PostBlock(
                            post: post,
                            renderMedia: !isHero,
                            mediaSlot: mediaSlot,
                            onLike: vm.togglePostLike,
                            onShare: () => _showComingSoon("Share"),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                          child: _CommentsSection(
                            vm: vm,
                            comments: comments,
                            onOpenThread: _openThread,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              CommentComposer(submitting: vm.submitting, onSubmit: vm.submit),
            ],
          );
        },
      ),
    );

    final controller = _ytController;
    if (controller != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          aspectRatio: 16 / 9,
          onReady: () {
            if (mounted) setState(() => _ytReady = true);
          },
        ),
        builder: (context, player) => buildScaffold(
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  player,
                  if (!_ytReady)
                    const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return buildScaffold(null);
  }
}

class _TransparentBackAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _TransparentBackAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostBlock extends StatelessWidget {
  const _PostBlock({
    required this.post,
    required this.onLike,
    required this.onShare,
    this.renderMedia = true,
    this.mediaSlot,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final bool renderMedia;
  // When provided (e.g. a YouTube player wired into YoutubePlayerBuilder
  // at the Scaffold level), this widget renders in place of the inline
  // media. Lets the parent own playback state without `_PostBlock` knowing
  // anything about it.
  final Widget? mediaSlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (renderMedia) ...[
          if (mediaSlot != null) mediaSlot! else PostMedia(post: post),
          Gap.h16,
        ],
        PostDetailsHeader(post: post),
        if (post.description.isNotEmpty) ...[
          Gap.h12,
          AppText.regular(
            post.description,
            fontSize: 12,
            height: 1.45,
            color: const Color(0xff202020),
          ),
        ],
        Gap.h18,
        PostActions(
          post: post,
          onLike: onLike,
          onComment: () {},
          onShare: onShare,
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
