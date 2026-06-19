import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application/views/application_view.dart";
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

  /// Reads the pre-fetched active-livestream state and routes off the
  /// cached AsyncValue. Never issues a fresh HTTP call from the tap path:
  /// - loading  → flushbar ("still checking")
  /// - error    → flushbar (the error message)
  /// - null     → flushbar ("no active livestream")
  /// - present  → upsert into [livestreamsCacheProvider] for instant
  ///              render, then navigate.
  void _onLiveTap() {
    final state = ref.read(activeLivestreamProvider);
    state.when(
      loading: () => DthFlushBar.instance.showGeneric(
        title: "Live",
        message: "Checking for an active livestream…",
      ),
      error: (err, _) => DthFlushBar.instance.showError(
        title: "Live",
        message: err is ApiFailure
            ? err.message
            : "Could not check livestream right now.",
      ),
      data: (stream) {
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
      },
    );
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
    final pollVm = ref.watch(pollViewModelProvider);
    final bannersVm = ref.watch(bannersViewModelProvider);
    return ValueListenableBuilder(
      valueListenable: vm.userModel,
      builder: (context, value, child) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Gap.h14,
                  AppHeader(onLiveTap: _onLiveTap),
                  Gap.h10,
                  Expanded(
                    child: vm.baseState.when(
                      busy: () => const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      error: (Failure failure) => Center(
                        child: Center(
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 48),
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
                          await vm.refreshTimeline();
                          await pollVm.loadPoll();
                          await bannersVm.loadBanners();
                          await ref.read(userStateProvider).getUserDetails();
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
                                      .value;
                                  if (live == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12),
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
                                        appModules.appModules.value?.reel !=
                                            true
                                    ? const SizedBox.shrink()
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          StoriesBar(
                                            stories: vm.stories,
                                            onStoryTap: (story) {
                                              MobileNavigationService.instance
                                                  .push(
                                                    StoriesView.path,
                                                    extra: {
                                                      RoutingArgumentKey
                                                              .reelUid:
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
                                child: bannersVm.banners.isEmpty
                                    ? const SizedBox.shrink()
                                    : Column(
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
                              SliverToBoxAdapter(
                                child: PollComponent(
                                  pollListenable: pollVm.poll,
                                  isVoteBusy: pollVm.isVoteBusy,
                                  onVoteTap: (optionUid) {
                                    unawaited(pollVm.vote(optionUid));
                                  },
                                ),
                              ),
                              if (vm.postUids.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Padding(
                                    padding: EdgeInsets.only(
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
                                  padding: EdgeInsets.only(bottom: bottomInset),
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
                                                    _bumpPostShareCount(
                                                      post.uid,
                                                    ),
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
          ),
        );
      },
    );
  }
}
