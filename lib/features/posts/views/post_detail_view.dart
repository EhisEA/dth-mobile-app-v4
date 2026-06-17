import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/data/data.dart" show CommentSort;
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/components/comment_composer.dart";
import "package:dth_v4/features/posts/components/comment_sort_header.dart";
import "package:dth_v4/features/posts/components/comment_tile.dart";
import "package:dth_v4/features/posts/components/post_actions.dart";
import "package:dth_v4/features/posts/components/post_detail_skeleton.dart";
import "package:dth_v4/features/posts/components/post_description.dart";
import "package:dth_v4/features/posts/components/post_header.dart";
import "package:dth_v4/features/posts/components/post_hero.dart";
import "package:dth_v4/features/posts/components/post_hero_image.dart";
import "package:dth_v4/features/posts/components/post_media.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/features/posts/view_model/comments_cache.dart";
import "package:dth_v4/features/posts/view_model/post_detail_view_model.dart";
import "package:dth_v4/features/posts/view_model/posts_cache.dart";
import "package:dth_v4/features/posts/views/comment_thread_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
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

  /// YouTube-style metadata collapse: as the comments list scrolls down past
  /// the pinned video, [_metaProgress] ramps 0 → 1 between [_metaFadeStart]
  /// and [_metaFadeStart] + [_metaFadeRange] pixels of scroll. The leading
  /// dead-zone keeps the header at full opacity while the meta block is
  /// still mostly on-screen; the fade only kicks in once the user is
  /// actually pushing it out of view.
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _metaProgress = ValueNotifier<double>(0);
  static const double _metaFadeStart = 80;
  static const double _metaFadeRange = 160;
  static const double _videoLiftPx = 6;
  static const double _metaSlidePx = 16;

  /// Single source of truth for the hero image's shape (width : height), shared
  /// by the [SliverAppBar] expanded height, the [PostHeroImage] aspect ratio
  /// and the collapse-fraction math so they can never drift apart. Height is
  /// derived from the live width, so it scales to any screen size.
  static const double _heroAspectRatio = 4 / 5;

  double _heroImageHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).width / _heroAspectRatio;

  /// Whether the current post uses the collapsing image app bar, and whether
  /// that bar has collapsed far enough to want dark status-bar icons. The
  /// SliverAppBar paints over the status bar in both states, so its own
  /// `systemOverlayStyle` must carry this — an outer AnnotatedRegion would be
  /// drawn behind it and ignored. `_imageCollapseDistance` is cached from the
  /// last build so [_onScroll] can evaluate the threshold without a context.
  bool _isImageHeroPost = false;
  bool _imageBarDark = false;
  double _imageCollapseDistance = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // If the post is already cached (e.g. coming from the feed) it's available
    // on the first build — but `ref.listen` only fires on *changes*, so we'd
    // miss the initial sync. Schedule it after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final post = ref.read(postDetailViewModelProvider(widget.uid)).post;
      if (post != null && _syncController(post)) setState(() {});
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Image posts: flip the status-bar icon brightness once the collapsing bar
    // is mostly white. Only fires on a threshold cross, so the setState is rare.
    if (_isImageHeroPost) {
      final dark = _scrollController.offset / _imageCollapseDistance > 0.5;
      if (dark != _imageBarDark) setState(() => _imageBarDark = dark);
    }
    final shifted = (_scrollController.offset - _metaFadeStart).clamp(
      0.0,
      _metaFadeRange,
    );
    final next = shifted / _metaFadeRange;
    // Skip imperceptible deltas so the ValueNotifier doesn't churn every
    // pixel — keeps the Opacity / Transform rebuilds cheap during fast flings.
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
    // No imperative status-bar reset here — each AppBar declares its own style
    // (DthAppBar -> theme dark, _TransparentBackAppBar -> light) and the home
    // shell's AnnotatedRegion(dark) reverts the bar on pop. An imperative reset
    // would race those declarative styles during the pop animation and leave
    // the bar stuck (the bug this screen used to show after YouTube fullscreen).
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

  /// Keep [_ytController] in sync with [post]'s video URL. Returns true when
  /// the controller changed so the caller can `setState` to mount the new one.
  /// Driven from `initState` (cached-post case) and a `ref.listen` callback
  /// in build (notifier updates) — never called during the build phase itself.
  bool _syncController(Post post) {
    final url = post.isVideo && (post.video?.isYoutube ?? false)
        ? post.video?.videoUrl
        : null;
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
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,

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
    return true;
  }

  void _openThread(String commentUid) {
    MobileNavigationService.instance.push(
      CommentThreadView.path,
      extra: {RoutingArgumentKey.commentUid: commentUid},
    );
  }

  @override
  Widget build(BuildContext context) {
    // React to post changes (initial load, navigated-to a different YT video)
    // outside of build itself. ChangeNotifierProvider fires this on every
    // `notifyListeners()`; `_syncController` short-circuits when the video id
    // hasn't changed, so only an actual URL flip triggers a setState/rebuild.
    ref.listen(postDetailViewModelProvider(widget.uid), (_, next) {
      final post = next.post;
      if (post != null && _syncController(post)) setState(() {});
    });

    final vm = ref.watch(postDetailViewModelProvider(widget.uid));
    final post = vm.post;

    // Cache owns Comment state; watch it so a like-toggle in the thread
    // screen rebuilds the comments list here automatically.
    final commentsCache = ref.watch(commentsCacheProvider);
    final comments = vm.commentUids
        .map(commentsCache.get)
        .whereType<Comment>()
        .toList(growable: false);

    final isImageHero =
        post != null && !post.isVideo && post.imageUrls.isNotEmpty;
    // Cache for [_onScroll] (runs without a build context).
    _isImageHeroPost = isImageHero;
    if (isImageHero) {
      _imageCollapseDistance =
          (_heroImageHeight(context) -
                  (kToolbarHeight + MediaQuery.paddingOf(context).top))
              .clamp(1.0, double.infinity);
    }
    // Known from the post data before the player controller is built. We pin a
    // thumbnail placeholder for this case so the [PostVideoHero] destination is
    // already in the tree when the card→detail hero flight starts (the
    // controller is only created in a post-frame callback, a frame too late).
    final isYoutubeVideo =
        post != null && post.isVideo && (post.video?.isYoutube ?? false);
    final isPinnedVideo = _ytController != null;
    // The pinned-video layout overlays a transparent back-only bar on the video
    // at the top. The image layout instead uses an in-scroll collapsing
    // [SliverAppBar] (see [_buildImageSliverAppBar]) so the bar carries the
    // back button below the status bar and the comments header pins under it,
    // rather than scrolling behind the status bar.
    final useTransparentBar = isYoutubeVideo;

    Widget buildScaffold(Widget? pinnedMedia) => Scaffold(
      extendBodyBehindAppBar: useTransparentBar,
      appBar: isImageHero
          ? null
          : (useTransparentBar
                ? const _TransparentBackAppBar()
                : DthAppBar(backgroundColor: Colors.white)),
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
                    child: CustomScrollView(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (isImageHero) _buildImageSliverAppBar(context, post),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              isImageHero || isPinnedVideo ? 16 : 12,
                              16,
                              24,
                            ),
                            child: _PostBlock(
                              post: post,
                              // Hero (image) and pinned (video) both render
                              // media themselves outside the post block — for
                              // youtube use the post-data flag (not the
                              // controller) so the placeholder frame matches.
                              renderMedia: !isImageHero && !isYoutubeVideo,
                              onLike: vm.togglePostLike,
                              onShare: () => LinkShareHelper.sharePost(
                                postUid: post.uid,
                                title: post.title,
                                description: post.description,
                                imageUrl: post.imageUrls.isNotEmpty
                                    ? post.imageUrls.first
                                    : "",
                                onShared: () {
                                  final cache = ref.read(postsCacheProvider);
                                  final current = cache.get(post.uid);
                                  if (current == null) return;
                                  cache.upsert(
                                    current.copyWith(
                                      shareCount: current.shareCount + 1,
                                    ),
                                  );
                                },
                              ),
                              // Only the pinned-video layout has a sticky media
                              // strip above the scroll — that's where the
                              // YouTube-style fade makes sense.
                              metaProgress: isPinnedVideo
                                  ? _metaProgress
                                  : null,
                            ),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _StickyCommentSortHeaderDelegate(
                            count: vm.post?.commentCount ?? comments.length,
                            sort: vm.sort,
                            onSortChanged: vm.setSort,
                          ),
                        ),
                        _CommentsSliver(
                          vm: vm,
                          comments: comments,
                          onOpenThread: _openThread,
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
        // youtube_player_flutter's default fullscreen callbacks reconfigure
        // SystemChrome (orientation + overlays) but never restore the
        // status-bar STYLE on exit, so the bar is left with the player's
        // default (dark icons over black) and that wrong style leaks back to
        // the timeline. Drive the transitions explicitly and re-assert the
        // post's light status bar (pinned video sits behind the transparent
        // light app bar) + lock back to portrait on exit.
        onEnterFullScreen: () {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          SystemChrome.setPreferredOrientations(const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        },
        onExitFullScreen: () {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
          SystemChrome.setPreferredOrientations(const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        },
        player: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          thumbnail: SizedBox.shrink(),
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
              // Flies from the feed card's video thumbnail. The hero's flight
              // shuttle paints the thumbnail still (see [PostVideoHero]); the
              // live player only takes over once the hero has landed.
              PostVideoHero(
                tag: postVideoHeroTag(post?.uid ?? ""),
                thumbnailUrl: post?.video?.thumbnailUrl ?? "",
                // Outer ColoredBox stays at the layout-allocated slot so the
                // 6px lift doesn't reveal the (light) scaffold colour beneath
                // the video — the bottom strip that briefly appears as the
                // inner Container translates upward stays black.
                child: ColoredBox(
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
              ),
            );
          },
        ),
      );
    }
    // YouTube post whose controller hasn't been built yet: pin a thumbnail
    // placeholder so the [PostVideoHero] destination exists for the incoming
    // card→detail flight. The player swaps in (above) once it's ready.
    if (isYoutubeVideo) {
      return buildScaffold(_pinnedVideoPlaceholder(context, post));
    }
    // The status-bar style for image posts is carried by the SliverAppBar's
    // own `systemOverlayStyle` (see [_buildImageSliverAppBar]) — it paints over
    // the status bar in both states, so an outer AnnotatedRegion here would be
    // overridden by it.
    return buildScaffold(null);
  }

  /// Scroll progress (0 = image fully expanded, 1 = bar fully collapsed) for
  /// the image-post [SliverAppBar]. Drives the back-button morph and the author
  /// title fade. (The status-bar style flips on a threshold in [_onScroll].)
  double _imageCollapseFraction(BuildContext context) {
    if (!_scrollController.hasClients) return 0;
    final expandedHeight = _heroImageHeight(context);
    final collapsedHeight = kToolbarHeight + MediaQuery.paddingOf(context).top;
    final distance = (expandedHeight - collapsedHeight).clamp(
      1.0,
      double.infinity,
    );
    return (_scrollController.offset / distance).clamp(0.0, 1.0);
  }

  /// Collapsing app bar for image posts: the hero image is the expanded
  /// background; as it scrolls away it collapses into a solid white bar (below
  /// the status bar) carrying the back button and the post author.
  Widget _buildImageSliverAppBar(BuildContext context, Post post) {
    // SliverAppBar adds the status-bar inset on top of `expandedHeight`
    // (maxExtent = topPadding + expandedHeight). Subtract it so the expanded
    // header is exactly the image height, not image height + status bar.
    final expandedHeight =
        _heroImageHeight(context) - MediaQuery.paddingOf(context).top;
    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black26,
      elevation: 0,
      // Subtle shadow only once content scrolls under the collapsed bar, so it
      // separates from the comments below.
      scrolledUnderElevation: 3,
      // Light icons over the image, dark over the white collapsed bar. Set here
      // (not via an outer AnnotatedRegion) because the app bar paints over the
      // status bar in both states and would otherwise force its default.
      systemOverlayStyle: _imageBarDark
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Center(
          child: _ImageAppBarBackButton(
            scroll: _scrollController,
            fraction: () => _imageCollapseFraction(context),
            onTap: () => Navigator.pop(context),
          ),
        ),
      ),
      title: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, _) {
          // Fade in only over the back half of the collapse so the author
          // doesn't appear while the image is still prominent.
          final t = _imageCollapseFraction(context);
          return Opacity(
            opacity: ((t - 0.5) * 2).clamp(0.0, 1.0),
            child: AppText.semiBold(
              post.authorName,
              fontSize: 16,
              color: AppColors.mainBlack,
              maxLines: 1,
            ),
          );
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: PostHeroImage(
          urls: post.imageUrls,
          heroPrefix: post.uid,
          aspectRatio: _heroAspectRatio,
        ),
      ),
    );
  }

  Widget _pinnedVideoPlaceholder(BuildContext context, Post post) {
    return PostVideoHero(
      tag: postVideoHeroTag(post.uid),
      thumbnailUrl: post.video?.thumbnailUrl ?? "",
      child: ColoredBox(
        color: Colors.black,
        child: Container(
          color: Colors.black,
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: post.video?.thumbnailUrl ?? "",
                  fit: BoxFit.cover,
                ),
                const ColoredBox(color: Color(0x66000000)),
                const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
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
}

/// Back button for the image-post [SliverAppBar] that morphs with the collapse
/// [fraction]: a dark translucent disc with a white arrow over the image (so
/// it reads against bright photos), fading to a bare dark arrow once the solid
/// white bar has taken over. Listens to [scroll] so it repaints as you scroll.
class _ImageAppBarBackButton extends StatelessWidget {
  const _ImageAppBarBackButton({
    required this.scroll,
    required this.fraction,
    required this.onTap,
  });

  final Listenable scroll;
  final double Function() fraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scroll,
      builder: (context, _) {
        final t = fraction();
        final discAlpha = (0.5 * (1 - t)).clamp(0.0, 0.5);
        final iconColor = Color.lerp(Colors.white, AppColors.mainBlack, t)!;
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 40,
            height: 40,
            child: ClipOval(
              child: Material(
                color: Colors.black.withValues(alpha: discAlpha),
                shape: const CircleBorder(),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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

class _PostBlock extends StatefulWidget {
  const _PostBlock({
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

  /// When non-null, the header + description section fades and slides upward
  /// as the value moves 0 → 1. Drives the YouTube-style metadata collapse
  /// when there's a pinned video above the scroll. Actions stay visible.
  final ValueListenable<double>? metaProgress;

  @override
  State<_PostBlock> createState() => _PostBlockState();
}

class _PostBlockState extends State<_PostBlock> {
  bool _descriptionExpanded = false;

  Widget _withMetaFade(Widget child) {
    final progress = widget.metaProgress;
    if (progress == null) return child;

    return ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (context, t, child) {
        return Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -t * _PostDetailViewState._metaSlidePx),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.post.description.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 12),
            child: PostDescription(
              text: widget.post.description,
              lineHeight: 1.45,
              onExpansionChanged: (expanded) {
                setState(() => _descriptionExpanded = expanded);
              },
            ),
          )
        : null;

    // Pinned-video scroll fade targets the header (and collapsed description).
    // Expanded copy stays fully opaque so long "Read more" text does not vanish
    // into the background while scrolling to comments.
    final meta = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _withMetaFade(PostDetailsHeader(post: widget.post)),
        if (description != null)
          _descriptionExpanded ? description : _withMetaFade(description),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.renderMedia) ...[PostMedia(post: widget.post), Gap.h16],
        meta,
        Gap.h18,
        Row(
          children: [
            Expanded(
              child: PostActions(
                post: widget.post,
                showContainer: true,
                onLike: widget.onLike,
                onComment: () {},
                onShare: widget.onShare,
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    SvgAssets.eye,
                    height: 16,
                    width: 16,
                    colorFilter: ColorFilter.mode(
                      Color(0XFF454545),
                      BlendMode.srcIn,
                    ),
                  ),
                  Gap.w4,
                  AppText.medium(
                    formatCount(widget.post.viewCount),
                    fontSize: 12,
                    color: Color(0XFF454545),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StickyCommentSortHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyCommentSortHeaderDelegate({
    required this.count,
    required this.sort,
    required this.onSortChanged,
  });

  final int count;
  final CommentSort sort;
  final void Function(CommentSort) onSortChanged;

  static const _background = Color(0xffFCFCFC);
  static const _height = 44.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: _background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: CommentSortHeader(
            title: "Comments",
            count: count,
            sort: sort,
            onSortChanged: onSortChanged,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCommentSortHeaderDelegate old) {
    return old.count != count || old.sort != sort;
  }
}

class _CommentsSliver extends StatelessWidget {
  const _CommentsSliver({
    required this.vm,
    required this.comments,
    required this.onOpenThread,
  });

  final PostDetailViewModel vm;
  final List<Comment> comments;
  final void Function(String commentUid) onOpenThread;

  @override
  Widget build(BuildContext context) {
    if (vm.commentsLoading && comments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator.adaptive(),
            ),
          ),
        ),
      );
    }

    if (vm.commentsError != null && comments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: _CommentsErrorState(
            message: vm.commentsError!.message,
            onRetry: () => vm.retryLoadComments(),
          ),
        ),
      );
    }

    if (comments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: AppText.regular(
            "Be the first to drop a banger.",
            fontSize: 12,
            color: AppColors.blackTint20,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == comments.length) {
            return vm.loadingMoreComments
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                : const SizedBox.shrink();
          }
          final c = comments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: CommentTile(
              comment: c,
              onTap: () => onOpenThread(c.uid),
              onLike: () => vm.toggleCommentLike(c),
              showReplyChip: true,
            ),
          );
        }, childCount: comments.length + (vm.loadingMoreComments ? 1 : 0)),
      ),
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
