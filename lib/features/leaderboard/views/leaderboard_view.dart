import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_participant_tile.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_podium.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_position_card.dart";
import "package:dth_v4/features/leaderboard/view_model/leaderboard_view_model.dart";
import "package:dth_v4/features/leaderboard/views/fan_rewards_guide_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({super.key});

  static const String path = NavigatorRoutes.leaderboard;

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  late final ScrollController _scrollController;
  bool _didOfferGuide = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    await ref.read(leaderboardViewModelProvider).load();
    if (!mounted) return;
    await _maybeShowGuide();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scrollController.position.pixels >= max - 400) {
      unawaited(ref.read(leaderboardViewModelProvider).loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _guideAlreadySeen =>
      ref
          .read(localCacheProvider)
          .getFromLocalCache(CacheKeys.fanRewardsGuideSeen) ==
      true;

  Future<void> _markGuideSeen() async {
    await ref
        .read(localCacheProvider)
        .saveToLocalCache(key: CacheKeys.fanRewardsGuideSeen, value: true);
  }

  Future<void> _openGuide({bool markSeen = false}) async {
    final guide = ref.read(leaderboardViewModelProvider).guide;
    if (guide == null || !guide.hasContent) {
      if (!markSeen) {
        DthFlushBar.instance.showGeneric(
          title: "Leaderboard",
          message: "Guide is not available right now.",
        );
      }
      return;
    }
    HapticFeedback.lightImpact();
    if (markSeen) await _markGuideSeen();
    if (!mounted) return;
    await MobileNavigationService.instance.navigateTo(
      FanRewardsGuideView.path,
      extra: {RoutingArgumentKey.fanRewardsGuide: guide},
    );
    if (!mounted) return;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  /// Auto-shows the Fan Rewards guide once until the user has seen it.
  Future<void> _maybeShowGuide() async {
    if (_didOfferGuide || !mounted) return;
    if (_guideAlreadySeen) {
      _didOfferGuide = true;
      return;
    }

    final guide = ref.read(leaderboardViewModelProvider).guide;
    if (guide == null || !guide.hasContent) return;

    _didOfferGuide = true;
    await _openGuide(markSeen: true);
  }

  void _onInfoTap() {
    unawaited(_openGuide());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(leaderboardViewModelProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.transparent,
                AppColors.greyTint15.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(ImageAssets.contestantBg),
                alignment: Alignment.topCenter,
                fit: BoxFit.fitWidth,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                SvgAssets.backArrow,
                                height: 20,
                                width: 20,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              AppText.semiBold(
                                vm.title,
                                fontSize: 16,
                                color: AppColors.tertiary60,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                height: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Gap.h(2),
                              AppText.regular(
                                vm.subtitle,
                                fontSize: 14,
                                color: AppColors.blackTint20,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _onInfoTap,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xff001119),
                              border: Border.all(
                                color: AppColors.white,
                                width: 8,
                              ),
                            ),

                            child: const Icon(
                              Icons.priority_high_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap.h16,
                  Expanded(
                    child: vm.baseState.when(
                      busy: () => const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      error: (Failure e) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText.regular(
                                e.message,
                                fontSize: 14,
                                color: AppColors.greyTint55,
                                textAlign: TextAlign.center,
                                multiText: true,
                              ),
                              Gap.h16,
                              AppButton.primary(
                                text: "Try again",
                                press: () => unawaited(vm.load()),
                              ),
                            ],
                          ),
                        ),
                      ),
                      idle: () => RefreshIndicator(
                        onRefresh: vm.refresh,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  Gap.h32,
                                  LeaderboardPodium(podium: vm.podium),
                                ],
                              ),
                            ),
                            if (vm.currentUser != null) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    0,
                                  ),
                                  child: LeaderboardPositionCard(
                                    entry: vm.currentUser!,
                                  ),
                                ),
                              ),
                            ],
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  24,
                                  16,
                                  24,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    if (vm.participants.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 32,
                                        ),
                                        child: AppText.regular(
                                          "No other participants yet.",
                                          fontSize: 13,
                                          color: AppColors.greyTint55,
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    else ...[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            20,
                                            20,
                                            20,
                                            0,
                                          ),
                                          child: AppText.bold(
                                            "OTHER PARTICIPANTS",
                                            fontSize: 9,
                                            letterSpacing: 1.8,
                                            color: AppColors.blackTint20,
                                          ),
                                        ),
                                      ),
                                      Gap.h16,
                                      ...vm.participants.map(
                                        (e) => LeaderboardParticipantTile(
                                          entry: e,
                                        ),
                                      ),
                                    ],
                                    if (vm.loadingMore)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 16),
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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
      ),
    );
  }
}
