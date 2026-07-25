import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application_dashboard/applicant_dashboard.dart";
import "package:dth_v4/features/home/home.dart";
import "package:dth_v4/features/livestream/components/livestream_banner.dart";
import "package:dth_v4/features/livestream/view_model/active_livestream_provider.dart";
import "package:dth_v4/features/livestream/view_model/livestreams_cache.dart";
import "package:dth_v4/features/livestream/views/livestream_view.dart";
import "package:dth_v4/features/posts/posts.dart";
import "package:dth_v4/features/notifications/notifications.dart";
import "package:dth_v4/features/stories/stories.dart";
import "package:dth_v4/features/polls/polls.dart";
import "package:dth_v4/features/subscription/subscription.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  static const String path = NavigatorRoutes.home;

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(homeViewModelProvider).loadTimeline());
      unawaited(ref.read(pollViewModelProvider).loadPoll());
      unawaited(ref.read(bannersViewModelProvider).loadBanners());
      unawaited(ref.read(sponsorshipsViewModelProvider).load());
      unawaited(
        ref.read(applicantDashboardViewModelProvider).prefetchForHomeUser(),
      );
      unawaited(ref.read(notificationsViewModelProvider).prefetchUnreadBadge());
      // Warm the active-livestream cache. The icon tap then reads the
      // resolved state synchronously — no HTTP roundtrip on tap.
      ref.read(activeLivestreamProvider);
      // Replay any deep link that arrived while logged out. Reaching home
      // means the user is authed, so the link's auth gate is now satisfied.
      DeepLinkRouter.instance.consumePendingLink();
    });
  }

  /// Optimistic +1 on a post's share count after a completed share. Reads the
  /// freshest post from the cache so a concurrent like/refresh isn't clobbered.
  void _bumpPostShareCount(String uid) {
    final cache = ref.read(postsCacheProvider);
    final current = cache.get(uid);
    if (current == null) return;
    cache.upsert(current.copyWith(shareCount: current.shareCount + 1));
  }

  /// Reads the pre-fetched active-livestream state and routes off the cached
  /// AsyncValue (refetches when subscribed but cache still has subscription_required).
  void _onLiveTap() {
    unawaited(_handleLiveTap());
  }

  void _routeForActiveStream(Livestream? stream) {
    if (stream == null) {
      DthFlushBar.instance.showGeneric(
        title: "Live",
        message: "There's no active livestream right now.",
      );
      return;
    }
    ref.read(livestreamsCacheProvider).upsert(stream);
    unawaited(
      MobileNavigationService.instance.navigateTo(
        LivestreamView.path,
        extra: {RoutingArgumentKey.livestreamUid: stream.uid},
      ),
    );
  }

  Future<void> _handleLiveTap() async {
    final asyncState = ref.read(activeLivestreamProvider);

    if (asyncState.isLoading) {
      DthFlushBar.instance.showGeneric(
        title: "Live",
        message: "Checking for an active livestream…",
      );
      return;
    }

    if (asyncState.hasError) {
      final err = asyncState.error;
      if (isSubscriptionRequiredFailure(err)) {
        final isSubscribed =
            ref.read(userStateProvider).user.value?.isSubscribed ?? false;
        if (isSubscribed) {
          ref.invalidate(activeLivestreamProvider);
          try {
            final stream = await ref.read(activeLivestreamProvider.future);
            if (!mounted) return;
            _routeForActiveStream(stream);
          } on ApiFailure catch (e) {
            if (!mounted) return;
            DthFlushBar.instance.showError(title: "Live", message: e.message);
          } on Object {
            if (!mounted) return;
            DthFlushBar.instance.showError(
              title: "Live",
              message: "Could not check livestream right now.",
            );
          }
          return;
        }
        if (!mounted) return;
        await showSubscriptionRequiredSheet(context);
        return;
      }
      DthFlushBar.instance.showError(
        title: "Live",
        message: err is ApiFailure
            ? err.message
            : "Could not check livestream right now.",
      );
      return;
    }

    if (asyncState.hasValue) {
      _routeForActiveStream(asyncState.value);
    }
  }

  Future<void> _refreshActiveLivestream() async {
    ref.invalidate(activeLivestreamProvider);
    try {
      await ref.read(activeLivestreamProvider.future);
    } on Object {
      // Banner/icon read valueOrNull; errors stay silent until live tap.
    }
  }

  @override
  Widget build(BuildContext context) {
    final appModules = ref.watch(appModulesStateProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom + 100;
    final vm = ref.watch(homeViewModelProvider);
    // The cache owns Post state; the VM owns order. Watching the cache here
    // means a like-toggle on the detail screen rebuilds this view automatically.
    final cache = ref.watch(postsCacheProvider);
    final posts = vm.postUids
        .map(cache.get)
        .whereType<Post>()
        .toList(growable: false);
    final pinnedPosts = vm.pinnedPostUids
        .map(cache.get)
        .whereType<Post>()
        .toList(growable: false);
    final pollVm = ref.watch(pollViewModelProvider);
    final bannersVm = ref.watch(bannersViewModelProvider);
    return ValueListenableBuilder(
      valueListenable: vm.userModel,
      builder: (context, value, child) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Gap.h14,
                      AppHeader(onLiveTap: _onLiveTap),
                      Gap.h10,
                    ],
                  ),
                ),
                Expanded(
                  child: vm.baseState.when(
                    busy: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    error: (Failure failure) => Center(
                      child: Center(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            vertical: 48,
                            horizontal: 16,
                          ),
                          children: [
                            AppText.semiBold(
                              "Could not load timeline",
                              fontSize: 16,
                              color: AppColors.mainBlack,
                              textAlign: TextAlign.center,
                            ),
                            Gap.h12,
                            AppText.regular(
                              failure.message,
                              fontSize: 14,
                              color: AppColors.blackTint20,
                              textAlign: TextAlign.center,
                            ),
                            Gap.h24,
                            Center(
                              child: AppButton.primary(
                                text: "Retry",
                                height: 48,
                                press: () => unawaited(vm.loadTimeline()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    idle: () => RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          vm.refreshTimeline(),
                          pollVm.loadPoll(),
                          bannersVm.loadBanners(),
                          ref.read(sponsorshipsViewModelProvider).load(),
                          ref.read(userStateProvider).getUserDetails(),
                          _refreshActiveLivestream(),
                        ]);
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          // Ignore nested horizontal lists (banners, reels)
                          // — their scroll metrics would otherwise trigger
                          // timeline pagination.
                          if (n.metrics.axis != Axis.vertical) return false;
                          // Trigger loadMore ~400px before the end.
                          // Guards inside loadMoreTimeline (hasMore +
                          // _loadingMore flag) make the firing here
                          // idempotent.
                          if (n.metrics.pixels >=
                              n.metrics.maxScrollExtent - 400) {
                            unawaited(vm.loadMoreTimeline());
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // Active-livestream banner. Reads the cached
                            // active-livestream state (warmed in initState)
                            // so it renders synchronously off whatever the
                            // pre-fetch resolved to — no tap-time HTTP.
                            SliverToBoxAdapter(
                              child: () {
                                final live = ref
                                    .watch(activeLivestreamProvider)
                                    .valueOrNull;
                                if (live == null) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    12,
                                  ),
                                  child: LivestreamBanner(
                                    stream: live,
                                    onTap: _onLiveTap,
                                  ),
                                );
                              }(),
                            ),
                            SliverToBoxAdapter(
                              child:
                                  vm.stories.isEmpty ||
                                      appModules.appModules.value?.reel != true
                                  ? const SizedBox.shrink()
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Full-bleed horizontally; left inset
                                        // lives on the ListView so cards can
                                        // scroll flush to the phone edge.
                                        StoriesBar(
                                          stories: vm.stories,
                                          onStoryTap: (story) {
                                            MobileNavigationService.instance
                                                .push(
                                                  StoriesView.path,
                                                  extra: {
                                                    RoutingArgumentKey.reelUid:
                                                        story.uid,
                                                  },
                                                );
                                          },
                                        ),
                                        Gap.h16,
                                      ],
                                    ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: PollComponent(
                                  pollListenable: pollVm.poll,
                                  isVoteBusy: pollVm.isVoteBusy,
                                  onVoteTap: (optionUid) {
                                    unawaited(pollVm.vote(optionUid));
                                  },
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: pinnedPosts.isEmpty
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          PinnedPostsBar(
                                            posts: pinnedPosts,
                                            onTap: (post) =>
                                                MobileNavigationService.instance
                                                    .push(
                                                      PostDetailView.path,
                                                      extra: {
                                                        RoutingArgumentKey
                                                                .postUid:
                                                            post.uid,
                                                      },
                                                    ),
                                            onLike: (uid) => unawaited(
                                              vm.togglePostLike(uid),
                                            ),
                                            onShare: (post) =>
                                                LinkShareHelper.sharePost(
                                                  postUid: post.uid,
                                                  title: post.title,
                                                  description: post.description,
                                                  imageUrl:
                                                      post.imageUrls.isNotEmpty
                                                      ? post.imageUrls.first
                                                      : "",
                                                  onShared: () =>
                                                      _bumpPostShareCount(
                                                        post.uid,
                                                      ),
                                                ),
                                          ),
                                          Gap.h16,
                                        ],
                                      ),
                                    ),
                            ),
                            SliverToBoxAdapter(
                              child: bannersVm.banners.isEmpty
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          HomeBannersBar(
                                            banners: bannersVm.banners,
                                          ),
                                          Gap.h16,
                                        ],
                                      ),
                                    ),
                            ),

                            // SliverToBoxAdapter(
                            //   child:
                            //       value?.participationRole ==
                            //               ParticipationRole.user &&
                            //           appModules
                            //                   .appModules
                            //                   .value
                            //                   ?.application ==
                            //               true
                            //       ? Column(
                            //           mainAxisSize: MainAxisSize.min,
                            //           crossAxisAlignment:
                            //               CrossAxisAlignment.stretch,
                            //           children: [
                            //             // Gap.h10,
                            //             GestureDetector(
                            //               behavior: HitTestBehavior.opaque,
                            //               onTap: () {
                            //                 MobileNavigationService.instance
                            //                     .navigateTo(
                            //                       ApplicationView.path,
                            //                     );
                            //               },
                            //               child: Container(
                            //                 height: 108,
                            //                 width: double.infinity,
                            //                 decoration: BoxDecoration(
                            //                   image: DecorationImage(
                            //                     image: AssetImage(
                            //                       ImageAssets.applyimg,
                            //                     ),
                            //                     fit: BoxFit.fill,
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //             Gap.h16,
                            //           ],
                            //         )
                            //       : const SizedBox.shrink(),
                            // ),
                            if (vm.postUids.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: bottomInset,
                                  ),
                                  child: Center(
                                    child: AppText.regular(
                                      "No posts yet.",
                                      fontSize: 14,
                                      color: AppColors.blackTint20,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: bottomInset,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    // Footer slot: loading spinner while
                                    // fetching the next page; nothing once
                                    // we've reached the end.
                                    if (index >= posts.length) {
                                      if (vm.loadingMore) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 24,
                                          ),
                                          child: Center(
                                            child:
                                                CircularProgressIndicator.adaptive(),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }
                                    final post = posts[index];
                                    final isLast = index == posts.length - 1;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: index == 0 ? 2 : 0,
                                        bottom: isLast ? 0 : 12,
                                      ),
                                      child: PostCard(
                                        post: post,
                                        onLike: () => unawaited(
                                          vm.togglePostLike(post.uid),
                                        ),
                                        onShare: () =>
                                            LinkShareHelper.sharePost(
                                              postUid: post.uid,
                                              title: post.title,
                                              description: post.description,
                                              imageUrl:
                                                  post.imageUrls.isNotEmpty
                                                  ? post.imageUrls.first
                                                  : "",
                                              onShared: () =>
                                                  _bumpPostShareCount(post.uid),
                                            ),
                                        onTap: () => MobileNavigationService
                                            .instance
                                            .push(
                                              PostDetailView.path,
                                              extra: {
                                                RoutingArgumentKey.postUid:
                                                    post.uid,
                                              },
                                            ),
                                      ),
                                    );
                                  }, childCount: posts.length + 1),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
