import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application/views/application_view.dart";
import "package:dth_v4/features/home/home.dart";
import "package:dth_v4/features/stories/views/stories_view.dart";
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 100;
    final vm = ref.watch(homeViewModelProvider);
    return ValueListenableBuilder(
      valueListenable: vm.userModel,
      builder: (context, value, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            body: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Gap.h14,
                    HomeHeader(onLiveTap: () {}, onNotificationTap: () {}),
                    Expanded(
                      child: vm.baseState.when(
                        busy: () => const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                        error: (Failure failure) => Center(
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
                        idle: () => RefreshIndicator(
                          onRefresh: () => vm.refreshTimeline(),
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: vm.stories.isEmpty
                                    ? const SizedBox.shrink()
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Gap.h16,
                                          HomeStoriesBar(
                                            stories: vm.stories,
                                            onStoryTap: (story) {
                                              MobileNavigationService.instance
                                                  .push(
                                                    StoriesView.path,
                                                    extra: {
                                                      RoutingArgumentKey
                                                              .imageUrl:
                                                          story.imageUrl,
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
                                        ParticipationRole.user
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
                              if (vm.posts.isEmpty)
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
                                      final post = vm.posts[index];
                                      final isLast =
                                          index == vm.posts.length - 1;
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          top: index == 0 ? 12 : 0,
                                          bottom: isLast ? 0 : 28,
                                        ),
                                        child: HomePostCard(post: post),
                                      );
                                    }, childCount: vm.posts.length),
                                  ),
                                ),
                            ],
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
      },
    );
  }
}
