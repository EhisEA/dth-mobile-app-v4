import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/home/home.dart";
import "package:dth_v4/features/tickets/tickets.dart";
import "package:dth_v4/features/voting/voting.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Matches bottom-nav content height in [BottomNavBar].
const double _kBottomNavContentHeight = 84;

double _bottomNavScrollPadding(BuildContext context) =>
    _kBottomNavContentHeight + MediaQuery.paddingOf(context).bottom;

class TicketView extends ConsumerStatefulWidget {
  const TicketView({super.key});

  @override
  ConsumerState<TicketView> createState() => _TicketViewState();
}

class _TicketViewState extends ConsumerState<TicketView> {
  late final PageController _pageController;
  late final ScrollController _purchasedScrollController;
  bool _ignorePageCallback = false;

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(ticketHomeViewModelProvider).tab;
    _pageController = PageController(initialPage: _indexFor(initialTab));
    _purchasedScrollController = ScrollController()
      ..addListener(_onPurchasedScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(ticketHomeViewModelProvider).refresh());
      unawaited(ref.read(sponsorshipsViewModelProvider).load());
    });
  }

  void _onPurchasedScroll() {
    if (!_purchasedScrollController.hasClients) return;
    final max = _purchasedScrollController.position.maxScrollExtent;
    if (max <= 0) return;
    if (_purchasedScrollController.position.pixels >= max - 400) {
      unawaited(ref.read(ticketHomeViewModelProvider).loadMoreBooked());
    }
  }

  @override
  void dispose() {
    _purchasedScrollController.removeListener(_onPurchasedScroll);
    _purchasedScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int _indexFor(TicketHomeTab tab) => tab == TicketHomeTab.upcoming ? 0 : 1;

  TicketHomeTab _tabFor(int index) =>
      index == 0 ? TicketHomeTab.upcoming : TicketHomeTab.purchased;

  Future<void> _onToggleChanged(TicketHomeTab next) async {
    final vm = ref.read(ticketHomeViewModelProvider);
    if (vm.tab == next) return;
    vm.setTab(next);
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
    ref.read(ticketHomeViewModelProvider).setTab(_tabFor(index));
  }

  void _openShow(EventListItem item) {
    MobileNavigationService.instance.navigateTo(
      ShowView.path,
      extra: {RoutingArgumentKey.eventUid: item.uid},
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(ticketHomeViewModelProvider);
    final listBottomPad = _bottomNavScrollPadding(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap.h10,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppText.medium(
                  "Tickets",
                  fontSize: 24,
                  color: AppColors.tertiary60,
                ),
              ),
              Gap.h8,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppText.regular(
                  "Don’t miss out — get your tickets and join the show live.",
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.paleLavender,
                ),
              ),
              Gap.h16,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TicketHomeToggle(
                  selected: vm.tab,
                  onChanged: (next) => unawaited(_onToggleChanged(next)),
                ),
              ),
              Gap.h16,
              const _TicketsSponsorStrip(),
              Gap.h4,
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _UpcomingListPage(
                      vm: vm,
                      listBottomPad: listBottomPad,
                      onOpenShow: _openShow,
                      onRefresh: () =>
                          ref.read(ticketHomeViewModelProvider).refresh(),
                    ),
                    _PurchasedListPage(
                      vm: vm,
                      bookedEvents: vm.bookedEvents,
                      scrollController: _purchasedScrollController,
                      listBottomPad: listBottomPad,
                      onOpenShow: _openShow,
                      onRefresh: () =>
                          ref.read(ticketHomeViewModelProvider).refresh(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingListPage extends StatelessWidget {
  const _UpcomingListPage({
    required this.vm,
    required this.listBottomPad,
    required this.onOpenShow,
    required this.onRefresh,
  });

  final TicketHomeViewModel vm;
  final double listBottomPad;
  final void Function(EventListItem item) onOpenShow;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return vm.upcomingState.maybeWhen(
      busy: () =>
          const TicketEventCardListSkeleton(mode: TicketEventCardMode.upcoming),
      error: (failure) => TicketEmptyState(
        title: "Could not load upcoming shows",
        subtitle: failure.message,
        onRetry: () => unawaited(vm.retryUpcoming()),
      ),
      idle: () {
        if (vm.upcomingPreview.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: listBottomPad),
              children: const [
                Gap.h(48),
                TicketEmptyState(
                  title: "Tickets Coming Soon",
                  subtitle:
                      "Ticket sales haven't started yet. Check back soon for upcoming shows.",
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 8, 16, listBottomPad),
            itemCount: vm.upcomingPreview.length,
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(height: 1, color: AppColors.greyTint20),
            ),
            itemBuilder: (context, index) {
              final item = vm.upcomingPreview[index];
              return TicketEventCard(
                event: item,
                mode: TicketEventCardMode.upcoming,
                onTap: () => onOpenShow(item),
                onBuyTicket: () => onOpenShow(item),
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _PurchasedListPage extends StatelessWidget {
  const _PurchasedListPage({
    required this.vm,
    required this.bookedEvents,
    required this.scrollController,
    required this.listBottomPad,
    required this.onOpenShow,
    required this.onRefresh,
  });

  final TicketHomeViewModel vm;
  final ValueNotifier<List<EventListItem>> bookedEvents;
  final ScrollController scrollController;
  final double listBottomPad;
  final void Function(EventListItem item) onOpenShow;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<EventListItem>>(
      valueListenable: bookedEvents,
      builder: (context, items, _) {
        return vm.bookedState.maybeWhen(
          busy: () => const TicketEventCardListSkeleton(
            mode: TicketEventCardMode.purchased,
          ),
          error: (failure) => TicketEmptyState(
            title: "Could not load purchased tickets",
            subtitle: failure.message,
            onRetry: () => unawaited(vm.retryBooked()),
          ),
          idle: () {
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: listBottomPad),
                  children: const [
                    SizedBox(height: 48),
                    TicketEmptyState(
                      title: "No Booked Shows",
                      subtitle:
                          "You haven't booked any shows yet. Purchase a ticket to show your bookings.",
                    ),
                  ],
                ),
              );
            }

            final loadingMore = vm.bookedLoadingMore;
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.separated(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 8, 16, listBottomPad),
                itemCount: items.length + (loadingMore ? 1 : 0),
                separatorBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(height: 1, color: AppColors.greyTint20),
                ),
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  }
                  final item = items[index];
                  return TicketEventCard(
                    event: item,
                    mode: TicketEventCardMode.purchased,
                    onTap: () => onOpenShow(item),
                  );
                },
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Sponsor strip under the Upcoming/Purchased switcher (`ticket` section).
class _TicketsSponsorStrip extends ConsumerWidget {
  const _TicketsSponsorStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(sponsorshipsViewModelProvider).ticket;
    if (section == null || !section.hasSponsors) {
      return const SizedBox.shrink();
    }
    if (!section.sponsors.any((s) => s.hasLogo)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImageAssets.sponsorBg),
          fit: BoxFit.fill,
        ),
      ),
      child: const VotingSponsorFooter(
        sectionName: "ticket",
        includeSafeAreaPadding: false,
        horizontalPadding: 16,
        topPadding: 8,
        bottomPadding: 8,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
