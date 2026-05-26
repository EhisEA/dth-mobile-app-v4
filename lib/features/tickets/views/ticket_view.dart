import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/tickets/tickets.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class TicketView extends ConsumerStatefulWidget {
  const TicketView({super.key});

  @override
  ConsumerState<TicketView> createState() => _TicketViewState();
}

class _TicketViewState extends ConsumerState<TicketView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(ticketHomeViewModelProvider).refresh());
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scrollController.position.pixels >= max - 400) {
      unawaited(ref.read(ticketHomeViewModelProvider).loadMoreBooked());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _openDescription(EventListItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: AppText.regular(
                item.shortDescription.isNotEmpty
                    ? item.shortDescription
                    : item.title,
                fontSize: 14,
                color: AppColors.blackTint20,
                multiText: true,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(ticketHomeViewModelProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
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
                  color: AppColors.paleLavender,
                ),
              ),
              Gap.h16,
              Expanded(
                child: _TicketHomeBody(
                  vm: vm,
                  bookedEvents: vm.bookedEvents,
                  scrollController: _scrollController,
                  onOpenDescription: _openDescription,
                  onRefresh: () =>
                      ref.read(ticketHomeViewModelProvider).refresh(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketHomeBody extends StatelessWidget {
  const _TicketHomeBody({
    required this.vm,
    required this.bookedEvents,
    required this.scrollController,
    required this.onOpenDescription,
    required this.onRefresh,
  });

  final TicketHomeViewModel vm;
  final ValueNotifier<List<EventListItem>> bookedEvents;
  final ScrollController scrollController;
  final void Function(EventListItem item) onOpenDescription;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<EventListItem>>(
      valueListenable: bookedEvents,
      builder: (context, bookedItems, _) {
        final bothBusy = vm.upcomingState.isBusy && vm.bookedState.isBusy;
        if (bothBusy) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final unifiedEmpty =
            vm.upcomingState.isIdle &&
            vm.bookedState.isIdle &&
            vm.upcomingPreview.isEmpty &&
            bookedItems.isEmpty;
        if (unifiedEmpty) {
          return const TicketEmptyState();
        }

        final showUpcomingBlock =
            vm.upcomingState.isBusy ||
            vm.upcomingState.isError ||
            (vm.upcomingState.isIdle && vm.upcomingPreview.isNotEmpty);

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              if (showUpcomingBlock) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.medium(
                        "Upcoming Shows",
                        fontSize: 12,
                        color: AppColors.black,
                      ),
                      if (vm.upcomingState.isIdle &&
                          vm.upcomingPreview.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            MobileNavigationService.instance.navigateTo(
                              UpcomingShowsView.path,
                            );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AppText.regular(
                            "See all",
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                Gap.h12,
                ..._upcomingSectionBody(context),
                Gap.h24,
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppText.medium(
                  "Booked Shows",
                  fontSize: 12,
                  color: AppColors.black,
                ),
              ),
              Gap.h12,
              ..._bookedSectionBody(context, bookedItems),
              if (vm.bookedLoadingMore) ...[
                Gap.h16,
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                ),
              ],
              Gap.h(100),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _upcomingSectionBody(BuildContext context) {
    return vm.upcomingState.maybeWhen(
      busy: () => [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          ),
        ),
      ],
      error: (failure) => const <Widget>[],
      idle: () {
        if (vm.upcomingPreview.isEmpty) return const <Widget>[];
        return [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                ...vm.upcomingPreview.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final cardWidth = context.width * 0.7;
                  final last = index == vm.upcomingPreview.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(right: last ? 0 : 12),
                    child: SizedBox(
                      width: cardWidth,
                      child: UpcomingShowsComponent(
                        imageUrl: item.displayImageUrl,
                        title: item.title,
                        description: item.shortDescription,
                        location: item.location,
                        dateTimeLabel: item.time,
                        showLocation: false,
                        showDescription: false,
                        showDivider: false,
                        onTap: () {
                          MobileNavigationService.instance.navigateTo(
                            ShowView.path,
                            extra: {RoutingArgumentKey.eventUid: item.uid},
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ];
      },
      orElse: () => const <Widget>[],
    );
  }

  List<Widget> _bookedSectionBody(
    BuildContext context,
    List<EventListItem> bookedEvents,
  ) {
    return vm.bookedState.maybeWhen(
      busy: () => [
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 32),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          ),
        ),
      ],
      error: (failure) => [
        Gap.h24,
        TicketEmptyState(
          title: "Could not load booked shows",
          subtitle: failure.message,
          onRetry: () => unawaited(vm.retryBooked()),
        ),
      ],
      idle: () {
        if (bookedEvents.isEmpty) {
          return [Gap.h24, TicketEmptyState()];
        }
        return bookedEvents.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0) Gap.h20,
              BookedShowsComponent(
                imageUrl: item.displayImageUrl,
                title: item.title,
                descriptionPreview: item.shortDescription,
                ticketQuantity: int.tryParse(item.ticketsCount) ?? 0,
                scheduleLabel: item.dateTimeLine,
                onReadMore: () => onOpenDescription(item),
                onViewTickets: () {
                  MobileNavigationService.instance.navigateTo(
                    ShowView.path,
                    extra: {RoutingArgumentKey.eventUid: item.uid},
                  );
                },
              ),
            ],
          );
        }).toList();
      },
      orElse: () => const <Widget>[],
    );
  }
}
