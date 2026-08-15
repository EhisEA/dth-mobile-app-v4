import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/voting.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Matches bottom-nav content height in [BottomNavBar].
const double _kBottomNavContentHeight = 84;

double _bottomNavScrollPadding(BuildContext context) =>
    _kBottomNavContentHeight + MediaQuery.paddingOf(context).bottom;

class VotingView extends ConsumerStatefulWidget {
  const VotingView({super.key});

  static const String path = NavigatorRoutes.voting;

  @override
  ConsumerState<VotingView> createState() => _VotingViewState();
}

class _VotingViewState extends ConsumerState<VotingView> {
  late final PageController _pageController;
  Timer? _silentRefreshTimer;
  bool _ignorePageCallback = false;
  bool _didOfferTutorial = false;

  static const _silentRefreshInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    final initialFilter = ref.read(votingViewModelProvider).filter;
    _pageController = PageController(initialPage: _indexFor(initialFilter));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    // Greet ASAP from splash-prefetched week data (no tutorial loading).
    unawaited(_maybeShowWelcomeTutorial());
    await ref.read(votingViewModelProvider).load();
    if (!mounted) return;
    _startSilentRefreshTimer();
    // Cold path: week wasn't ready at first paint — try again after load.
    await _maybeShowWelcomeTutorial();
  }

  void _startSilentRefreshTimer() {
    _silentRefreshTimer?.cancel();
    _silentRefreshTimer = Timer.periodic(_silentRefreshInterval, (_) {
      unawaited(ref.read(votingViewModelProvider).silentRefresh());
    });
  }

  bool get _tutorialAlreadySeen =>
      ref
          .read(localCacheProvider)
          .getFromLocalCache(CacheKeys.votingTutorialSeen) ==
      true;

  Future<void> _markTutorialSeen() async {
    await ref
        .read(localCacheProvider)
        .saveToLocalCache(key: CacheKeys.votingTutorialSeen, value: true);
  }

  Future<void> _openVotingTutorial() async {
    if (!mounted) return;
    final vm = ref.read(votingViewModelProvider);
    await showWeeklyVotingCreditsSheet(
      context,
      credits: vm.credits,
      tutorial: vm.tutorial,
      onCompleted: () => unawaited(_markTutorialSeen()),
    );
  }

  /// Auto-shows the welcome sheet once per install until the user finishes
  /// the final CTA. Only runs while this tab is actively ticking (visible).
  Future<void> _maybeShowWelcomeTutorial() async {
    if (_didOfferTutorial || !mounted) return;
    if (!TickerMode.valuesOf(context).enabled) return;
    if (_tutorialAlreadySeen) {
      _didOfferTutorial = true;
      return;
    }

    final vm = ref.read(votingViewModelProvider);
    if (!vm.weekLoaded) return;

    _didOfferTutorial = true;
    await _openVotingTutorial();
  }

  @override
  void dispose() {
    _silentRefreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  int _indexFor(VotingFilter filter) =>
      filter == VotingFilter.upForEviction ? 0 : 1;

  VotingFilter _filterFor(int index) =>
      index == 0 ? VotingFilter.upForEviction : VotingFilter.allContestants;

  Future<void> _onToggleChanged(VotingFilter next) async {
    final vm = ref.read(votingViewModelProvider);
    if (vm.filter == next) return;
    vm.setFilter(next);
    _ignorePageCallback = true;
    await _pageController.animateToPage(
      _indexFor(next),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
    _ignorePageCallback = false;
  }

  void _onPageChanged(int index) {
    if (_ignorePageCallback) return;
    ref.read(votingViewModelProvider).setFilter(_filterFor(index));
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(votingViewModelProvider);
    final listBottomPad = _bottomNavScrollPadding(context);

    // When the user first switches onto this tab, TickerMode flips on — offer
    // the greeting if splash already warmed week data.
    if (TickerMode.valuesOf(context).enabled && !_didOfferTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_maybeShowWelcomeTutorial());
      });
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Gap.h10,
              VotingHeader(
                credits: vm.credits,
                onTap: () => unawaited(_openVotingTutorial()),
              ),
              Gap.h10,
              AppText.regular(
                "Vote to keep your favorite contestants in the competition.",
                fontSize: 14,
                height: 1,
                color: AppColors.paleLavender,
                multiText: true,
              ),
              Gap.h16,
              VotingFilterToggle(
                selected: vm.filter,
                onChanged: (next) => unawaited(_onToggleChanged(next)),
              ),
              Gap.h16,
              Expanded(
                child: vm.loadState.when(
                  busy: () => const _VotingSkeletonList(),
                  error: (failure) => EmptyState(
                    illustration: Icon(
                      Icons.how_to_vote_outlined,
                      size: 56,
                      color: AppColors.tint15,
                    ),
                    title: "Could not load voting",
                    subtitle: failure.message,
                    showDashedDivider: false,
                    onRetry: () => unawaited(_bootstrap()),
                  ),
                  idle: () => PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _ContestantListPage(
                        filter: VotingFilter.upForEviction,
                        listBottomPad: listBottomPad,
                      ),
                      _ContestantListPage(
                        filter: VotingFilter.allContestants,
                        listBottomPad: listBottomPad,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContestantListPage extends ConsumerWidget {
  const _ContestantListPage({
    required this.filter,
    required this.listBottomPad,
  });

  final VotingFilter filter;
  final double listBottomPad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(votingViewModelProvider);
    final items = vm.contestantsFor(filter);
    final isAllContestants = filter == VotingFilter.allContestants;

    if (items.isEmpty) {
      return Column(
        children: [
          Gap.h32,
          Gap.h10,
          VotingEmptyState(filter: filter),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: listBottomPad),
        itemCount: items.length,
        separatorBuilder: (_, __) => Gap.h12,
        itemBuilder: (context, index) {
          final contestant = items[index];
          void openAbout() {
            unawaited(
              MobileNavigationService.instance.push(
                AboutContestantView.path,
                extra: {RoutingArgumentKey.contestantUid: contestant.uid},
              ),
            );
          }

          return ContestantVoteCard(
            contestant: contestant,
            action: isAllContestants
                ? ContestantCardAction.viewDetails
                : ContestantCardAction.vote,
            onOpenAbout: openAbout,
            voteEnabled: !vm.isVoteBusy && contestant.canCastVote,
            onVote: !isAllContestants && contestant.canCastVote
                ? () => showVoteForContestantSheet(
                    context,
                    ref,
                    contestant: contestant,
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _VotingSkeletonList extends StatelessWidget {
  const _VotingSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      separatorBuilder: (_, __) => Gap.h12,
      itemBuilder: (_, __) => const ContestantVoteCardSkeleton(),
    );
  }
}
