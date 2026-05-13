import "dart:async";

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

  /// Latches true on the first `isReady` event for the current controller.
  /// `youtube_player_flutter` momentarily drops `isReady` back to false when
  /// the video ends and its replay overlay appears — without this latch our
  /// loading mask would reappear on top of the replay/retry button.
  bool _hasBeenReady = false;
  VoidCallback? _ytListener;

  @override
  void dispose() {
    _detachYtListener();
    _ytController?.dispose();
    // [_TransparentBackAppBar] uses SystemUiOverlayStyle.light; without a
    // reset, that style outlives this route because home uses no AppBar.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _attachYtListener(YoutubePlayerController c) {
    void listener() {
      if (_hasBeenReady) return;
      if (c.value.isReady && mounted) {
        setState(() => _hasBeenReady = true);
      }
    }

    _ytListener = listener;
    c.addListener(listener);
  }

  void _detachYtListener() {
    if (_ytListener != null && _ytController != null) {
      _ytController!.removeListener(_ytListener!);
    }
    _ytListener = null;
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
    _detachYtListener();
    _ytController?.dispose();
    _ytVideoId = newId;
    _hasBeenReady = false;
    _ytController = newId == null
        ? null
        : YoutubePlayerController(
            initialVideoId: newId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: true,

              // enableCaption: false,
              // forceHD: false,
              // // Don't render YT's red-play-button thumbnail before the
              // // video starts — our black loading mask covers initial state.
              // hideThumbnail: true,
              // Loop on end so YouTube's "suggested videos" end-screen
              // never has a chance to appear. YT removed the API ability
              // to disable that overlay around 2018, so looping is the
              // only way to suppress it.
              // loop: true,
            ),
          );
    final c = _ytController;
    if (c != null) {
      _attachYtListener(c);
    }
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

    final isImageHero =
        post != null && !post.isVideo && post.imageUrls.isNotEmpty;
    final isPinnedVideo = _ytController != null;
    // Either case wants the transparent back-only app bar overlaying the
    // media at the top of the screen.
    final useTransparentBar = isImageHero || isPinnedVideo;

    Widget buildScaffold(Widget? pinnedMedia) => Scaffold(
      extendBodyBehindAppBar: useTransparentBar,
      appBar: useTransparentBar
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
              // Pinned media sits OUTSIDE the scroll area — the post body
              // and comments scroll underneath, the video stays in place.
              if (pinnedMedia != null) pinnedMedia,
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [
                        if (isImageHero) PostHeroImage(urls: post.imageUrls),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            isImageHero || isPinnedVideo ? 16 : 12,
                            16,
                            0,
                          ),
                          child: _PostBlock(
                            post: post,
                            // Hero (image) and pinned (video) both render
                            // media themselves outside the post block.
                            renderMedia: !isImageHero && !isPinnedVideo,
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
          // Strip the default top overlay row (video title, share, "more").
          // We only want our control bar at the bottom and the video itself.
          topActions: const [],
        ),
        builder: (context, player) => ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final v = controller.value;
            // Latched: once the player has been ready, never show the mask
            // again. The package briefly flips `isReady` back to false during
            // end-of-video transitions, and we don't want our spinner to
            // come back on top of YT's retry / replay overlay.
            final showLoadingMask = !_hasBeenReady && !v.hasError;
            return buildScaffold(
              Container(
                color: Colors.black,
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      player,
                      if (showLoadingMask)
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
            );
          },
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
      backgroundColor: Colors.white.withValues(alpha: 0),
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      // Default leadingWidth is 56dp — same as (left padding 16) + (button 40).
      // The AppBar's internal padding can then nibble the button. Bumping the
      // slot keeps the button fully round.
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Center(
            // ClipOval defines a circular region. The BackdropFilter is
            // a Stack child sized via StackFit.expand so its blur reach
            // matches the clip — otherwise the blur only covers whatever
            // its direct child sizes to (the icon), and reads as a tiny
            // square in the middle of the circle.
            child: SizedBox(
              width: 40,
              height: 40,
              child: ClipOval(
                clipBehavior: Clip.hardEdge,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
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
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final bool renderMedia;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (renderMedia) ...[PostMedia(post: post), Gap.h16],
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
