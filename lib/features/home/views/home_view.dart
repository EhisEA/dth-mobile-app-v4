import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application/views/application_view.dart";
import "package:dth_v4/features/application_dashboard/applicant_dashboard.dart";
import "package:dth_v4/features/home/home.dart";
import "package:dth_v4/features/posts/posts.dart";
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
      unawaited(
        ref.read(applicantDashboardViewModelProvider).prefetchForHomeUser(),
      );
    });
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
                  AppHeader(onLiveTap: () {}),
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
                        },
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
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
                                          Gap.h16,
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
                                child:
                                    value?.participationRole ==
                                            ParticipationRole.user &&
                                        appModules
                                                .appModules
                                                .value
                                                ?.application ==
                                            true
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Gap.h10,
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              MobileNavigationService.instance
                                                  .navigateTo(
                                                    ApplicationView.path,
                                                  );
                                            },
                                            child: Container(
                                              height: 108,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                    ImageAssets.applyimg,
                                                  ),
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Gap.h10,
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
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
                                          top: index == 0 ? 12 : 0,
                                          bottom: isLast ? 0 : 12,
                                        ),
                                        child: PostCard(
                                          post: post,
                                          onLike: () => unawaited(
                                            vm.togglePostLike(post.uid),
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
