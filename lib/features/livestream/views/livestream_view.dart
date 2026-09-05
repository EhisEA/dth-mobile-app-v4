import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/livestream/view_model/livestream_detail_view_model.dart";
import "package:dth_v4/features/posts/components/comment_composer.dart";
import "package:dth_v4/features/posts/components/comment_sort_header.dart";
import "package:dth_v4/features/posts/components/comment_tile.dart";
import "package:dth_v4/features/posts/components/post_actions.dart";
import "package:dth_v4/features/posts/components/post_description.dart";
import "package:dth_v4/features/posts/components/post_detail_skeleton.dart";
import "package:dth_v4/features/posts/components/post_header.dart";
import "package:dth_v4/features/posts/components/post_media.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/features/posts/view_model/comments_cache.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:youtube_player_flutter/youtube_player_flutter.dart";

/// Active-livestream screen. Visually identical to [PostDetailView] — wraps
/// the same components by mapping [Livestream] → a synthetic [Post] for
/// rendering. Differences from posts: never an image hero (always video),
/// no reply threads on comments (API doesn't expose them), and an
/// explicit "stream ended" empty state when the active-stream fetch
/// returns null.
class LivestreamView extends ConsumerStatefulWidget {
  const LivestreamView({super.key, required this.uid});

  static const String path = NavigatorRoutes.livestream;

  final String uid;

  @override
  ConsumerState<LivestreamView> createState() => _LivestreamViewState();
}

class _LivestreamViewState extends ConsumerState<LivestreamView> {
  YoutubePlayerController? _ytController;
  String? _ytVideoId;
  bool _hasBeenReady = false;
  VoidCallback? _ytListener;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _metaProgress = ValueNotifier<double>(0);
  static const double _metaFadeStart = 80;
  static const double _metaFadeRange = 160;
  static const double _videoLiftPx = 6;
  static const double _metaSlidePx = 16;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stream = ref
          .read(livestreamDetailViewModelProvider(widget.uid))
          .livestream;
      if (stream != null && _syncController(stream)) setState(() {});
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shifted = (_scrollController.offset - _metaFadeStart).clamp(
      0.0,
      _metaFadeRange,
    );
    final next = shifted / _metaFadeRange;
    if ((next - _metaProgress.value).abs() < 0.005) return;
    _metaProgress.value = next;
  }

  @override
  void dispose() {
    _detachYtListener();
    _ytController?.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _metaProgress.dispose();
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

  /// Reuses [PostDetailView]'s controller-swap pattern. Returns true if the
  /// video id changed so the caller can `setState` to remount the player.
  bool _syncController(Livestream stream) {
    final url = stream.videoLink;
    final newId = url == null ? null : YoutubePlayer.convertUrlToId(url);
    if (newId == _ytVideoId) return false;
    _detachYtListener();
    _ytController?.dispose();
    _ytVideoId = newId;
    _hasBeenReady = false;
    _ytController = newId == null
        ? null
        : YoutubePlayerController(
            initialVideoId: newId,
            flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
          );
    final c = _ytController;
    if (c != null) {
      _attachYtListener(c);
    }
    return true;
  }

  /// Builds the synthetic [Post] used to feed [PostDetailsHeader],
  /// [PostMedia], [PostActions] etc. so the livestream screen reuses every
  /// existing component without forking them.
  Post _asPost(Livestream stream) {
    final link = stream.videoLink?.trim() ?? "";
    final thumb = stream.videoThumbnail?.trim() ?? "";
    final isVideo = link.isNotEmpty || thumb.isNotEmpty;
    return Post(
      uid: stream.uid,
      authorName: "Live",
      title: stream.title,
      description: stream.description,
      likeCount: stream.counts.reactions,
      commentCount: stream.counts.comments,
      shareCount: stream.counts.shares,
      viewCount: stream.counts.views,
      viewerReacted: stream.viewerReacted,
      createdAt: stream.createdAt,
      video: isVideo
          ? PostVideo(
              thumbnailUrl: thumb,
              videoUrl: link.isNotEmpty ? link : null,
              provider: "youtube",
            )
          : null,
      imageUrls: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(livestreamDetailViewModelProvider(widget.uid), (_, next) {
      final stream = next.livestream;
      if (stream != null && _syncController(stream)) setState(() {});
    });

    final vm = ref.watch(livestreamDetailViewModelProvider(widget.uid));
    final stream = vm.livestream;

    final commentsCache = ref.watch(commentsCacheProvider);
    final comments = vm.commentUids
        .map(commentsCache.get)
        .whereType<Comment>()
        .toList(growable: false);

    final isPinnedVideo = _ytController != null;
    final useTransparentBar = isPinnedVideo;

    Widget buildScaffold(Widget? pinnedMedia) => Scaffold(
      extendBodyBehindAppBar: useTransparentBar,
      appBar: useTransparentBar
          ? const _TransparentBackAppBar()
          : DthAppBar(backgroundColor: Colors.white, title: "Live"),
      backgroundColor: const Color(0xffFCFCFC),
      body: vm.baseState.when(
        busy: () => const PostDetailSkeleton(),
        error: (Failure failure) =>
            _ErrorState(message: failure.message, onRetry: () => vm.refresh()),
        idle: () {
          if (vm.streamEnded) {
            return _EmptyState(onRefresh: () => vm.refresh());
          }
          if (stream == null) {
            return const PostDetailSkeleton();
          }
          final post = _asPost(stream);
          return Column(
            children: [
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
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            isPinnedVideo ? 16 : 12,
                            16,
                            0,
                          ),
                          child: _LivestreamBlock(
                            post: post,
                            renderMedia: !isPinnedVideo,
                            onLike: vm.toggleLike,
                            onShare: () => LinkShareHelper.shareLivestream(
                              livestreamUid: stream.uid,
                              title: stream.title,
                              description: stream.description,
                              imageUrl: stream.videoThumbnail?.trim() ?? "",
                              onShared: vm.onShared,
                            ),
                            metaProgress: isPinnedVideo ? _metaProgress : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                          child: _CommentsSection(vm: vm, comments: comments),
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
          topActions: const [],
        ),
        builder: (context, player) => ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final v = controller.value;
            final showLoadingMask = !_hasBeenReady && !v.hasError;
            return buildScaffold(
              ColoredBox(
                color: Colors.black,
                child: ValueListenableBuilder<double>(
                  valueListenable: _metaProgress,
                  builder: (context, t, child) {
                    return Transform.translate(
                      offset: Offset(0, -t * _videoLiftPx),
                      child: child,
                    );
                  },
                  child: Container(
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
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Center(
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

class _LivestreamBlock extends StatelessWidget {
  const _LivestreamBlock({
    required this.post,
    required this.onLike,
    required this.onShare,
    this.renderMedia = true,
    this.metaProgress,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final bool renderMedia;
  final ValueListenable<double>? metaProgress;

  @override
  Widget build(BuildContext context) {
    final headerAndDescription = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PostDetailsHeader(post: post),
        if (post.description.isNotEmpty) ...[
          Gap.h12,
          PostDescription(text: post.description, lineHeight: 1.45),
        ],
      ],
    );

    final progress = metaProgress;
    final meta = progress == null
        ? headerAndDescription
        : ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, t, child) {
              return Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -t * _LivestreamViewState._metaSlidePx),
                  child: child,
                ),
              );
            },
            child: headerAndDescription,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (renderMedia) ...[PostMedia(post: post), Gap.h16],
        meta,
        Gap.h18,
        PostActions(
          post: post,
          showContainer: true,
          onLike: onLike,
          onComment: () {},
          onShare: onShare,
        ),
      ],
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({required this.vm, required this.comments});

  final LivestreamDetailViewModel vm;
  final List<Comment> comments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommentSortHeader(
          title: "Comments",
          count: vm.livestream?.counts.comments ?? comments.length,
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
              "Be the first to chime in.",
              fontSize: 12,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          ...comments.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              // Livestream comments don't expose replies — onTap is null and
              // the reply chip is hidden so the tile reads as terminal.
              child: CommentTile(
                comment: c,
                onLike: () => vm.toggleCommentLike(c),
                showReplyChip: false,
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
            "Could not load livestream",
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.semiBold(
              "Stream has ended",
              fontSize: 16,
              color: AppColors.mainBlack,
              textAlign: TextAlign.center,
            ),
            Gap.h12,
            AppText.regular(
              "There's no active livestream right now. Check back soon.",
              fontSize: 14,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
            ),
            Gap.h24,
            AppButton.primary(text: "Refresh", height: 48, press: onRefresh),
          ],
        ),
      ),
    );
  }
}
