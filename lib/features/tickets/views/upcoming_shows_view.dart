import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/tickets/components/ticket_empty_state.dart";
import "package:dth_v4/features/tickets/components/upcoming_shows_component.dart";
import "package:dth_v4/features/tickets/view_model/upcoming_shows_list_view_model.dart";
import "package:dth_v4/features/tickets/views/show_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class UpcomingShowsView extends ConsumerStatefulWidget {
  const UpcomingShowsView({super.key});

  static const String path = NavigatorRoutes.upcomingShows;

  @override
  ConsumerState<UpcomingShowsView> createState() => _UpcomingShowsViewState();
}

class _UpcomingShowsViewState extends ConsumerState<UpcomingShowsView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(upcomingShowsListViewModelProvider).loadFirstPage());
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scrollController.position.pixels >= max - 400) {
      unawaited(ref.read(upcomingShowsListViewModelProvider).loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(upcomingShowsListViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: const DthAppBar(title: "Upcoming Shows"),
      body: SafeArea(
        child: vm.baseState.when(
          busy: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (Failure failure) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            children: [
              TicketEmptyState(
                title: "Could not load shows",
                subtitle: failure.message,
                onRetry: () => unawaited(vm.loadFirstPage()),
              ),
            ],
          ),
          idle: () => RefreshIndicator(
            onRefresh: () => vm.refresh(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: vm.items.length + (vm.loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= vm.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
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
                final item = vm.items[index];
                return UpcomingShowsComponent(
                  imageUrl: item.displayImageUrl,
                  title: item.title,
                  description: item.shortDescription,
                  location: item.location,
                  dateTimeLabel: item.dateTimeLine,
                  showDivider: index < vm.items.length - 1,
                  onTap: () {
                    MobileNavigationService.instance.navigateTo(
                      ShowView.path,
                      extra: {RoutingArgumentKey.eventUid: item.uid},
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
