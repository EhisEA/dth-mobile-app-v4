import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/tickets/components/show_about_event_panel.dart";
import "package:dth_v4/features/tickets/components/show_buy_ticket.dart";
import "package:dth_v4/features/tickets/components/show_detail_hero.dart";
import "package:dth_v4/features/tickets/components/show_event_quick_info_row.dart";
import "package:dth_v4/features/tickets/components/show_purchased_tickets_section.dart";
import "package:dth_v4/features/tickets/components/show_scroll_hint_pill.dart";
import "package:dth_v4/features/tickets/components/show_view_skeleton.dart";
import "package:dth_v4/features/tickets/components/ticket_empty_state.dart";
import "package:dth_v4/features/tickets/components/show_status_chip.dart";
import "package:dth_v4/features/tickets/view_model/event_detail_view_model.dart";
import "package:dth_v4/features/tickets/models/your_tickets_args.dart";
import "package:dth_v4/features/tickets/views/purchase_tickets_view.dart";
import "package:dth_v4/features/tickets/views/your_tickets_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class ShowView extends ConsumerStatefulWidget {
  const ShowView({super.key, required this.eventUid});

  static const String path = NavigatorRoutes.show;

  final String eventUid;

  static const String kDefaultAboutBody =
      "De9jaspiriTalentHunt is back, and this time it's bigger and better than ever before! Prepare yourself for an exhilarating experience filled with music, culture, and unforgettable performances.\n\n"
      "Whether you are cheering from the crowd or joining us online, this week celebrates tradition, royalty, and the journey from street to stardom.";

  @override
  ConsumerState<ShowView> createState() => _ShowViewState();
}

class _ShowViewState extends ConsumerState<ShowView> {
  /// How close to [ScrollPosition.maxScrollExtent] counts as "at the bottom".
  static const double _scrollBottomTolerancePx = 24;

  /// Scrolls event details + purchased tickets; buy CTA is pinned below this.
  late final ScrollController _scrollController;

  /// Whether the floating "Continue reading" pill is visible.
  bool _showScrollHint = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// True when the user has scrolled to (or near) the purchased-tickets section.
  bool _isAtScrollBottom() {
    // Not laid out yet — treat as bottom so the pill does not flash on first frame.
    //NB: hasClients on a ScrollController means the controller is currently attached to at least one scrollable widget (e.g. ListView, SingleChildScrollView).
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    // All content fits on screen; nothing to scroll.
    if (position.maxScrollExtent <= 0) return true;
    return position.pixels >=
        position.maxScrollExtent - _scrollBottomTolerancePx;
  }

  // called every time the user scrolls (or when scroll position changes programmatically, e.g. after tapping the pill).
  void _onScroll() => _syncScrollHintVisibility();

  /// Shows the hint when there are purchased tickets and content below the fold.
  void _syncScrollHintVisibility({EventDetail? event}) {
    if (!mounted) return;

    // getting event from the view model or passing it in as an argument
    final detail =
        event ?? ref.read(eventDetailViewModelProvider(widget.eventUid)).event;
    // checking if the event has purchased tickets and if the user is not at the scroll bottom
    final next =
        detail != null &&
        detail.purchasedTickets.isNotEmpty &&
        !_isAtScrollBottom();
    // updating the state if the hint should be shown or not
    if (next != _showScrollHint) {
      setState(() => _showScrollHint = next);
    }

    // On every scroll, decide “purchased tickets exist and user hasn’t scrolled down far enough”; if that yes/no changed, show or hide the pill.
  }

  /// Pill tap: scroll to purchased tickets (buy button stays pinned below).
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventUid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: const DthAppBar(title: "Event"),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppText.regular(
              "Missing event reference.",
              fontSize: 14,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final vm = ref.watch(eventDetailViewModelProvider(widget.eventUid));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: vm.baseState.when(
        busy: () => const ShowViewSkeleton(),
        error: (Failure failure) => SafeArea(
          child: ListView(
            children: [
              Gap.h(16),
              Row(
                children: [
                  Gap.w16,
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xffF7F7F7),
                      ),
                      child: SvgPicture.asset(
                        SvgAssets.backArrow,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Gap.h24,
              TicketEmptyState(
                title: "Could not load event",
                subtitle: failure.message,
                onRetry: () => unawaited(vm.refresh()),
              ),
            ],
          ),
        ),

        idle: () {
          final event = vm.event;
          if (event == null) {
            return const ShowViewSkeleton();
          }

          final heroUrl = event.heroImageUrl.isNotEmpty
              ? event.heroImageUrl
              : "https://picsum.photos/seed/${event.uid}/960/540";
          final about = event.description.trim().isNotEmpty
              ? event.description
              : (event.shortDescription.trim().isNotEmpty
                    ? event.shortDescription
                    : ShowView.kDefaultAboutBody);
          final detailDate = event.dateFull.trim().isNotEmpty
              ? event.dateFull
              : event.date;
          final detailTime = event.time.trim().isNotEmpty ? event.time : "—";
          final detailVenue = event.location.trim().isNotEmpty
              ? event.location
              : "—";

          // Sync the scroll hint after layout, not during build():
          // _isAtScrollBottom() needs scroll metrics (pixels, maxScrollExtent) from the
          // SingleChildScrollView, which exist only once layout has run. In build() the
          // view is not measured yet, and setState is not allowed.
          // addPostFrameCallback runs after build → layout → paint, so we can read scroll
          // position and show/hide the pill safely (e.g. first open or new tickets).

          // checking if the event has purchased tickets
          final hasPurchasedTickets = event.purchasedTickets.isNotEmpty;
          // After layout, measure scroll extent so the hint is correct on first paint.
          // After layout, either sync the pill for purchased tickets, or turn it off if there are none.
          if (hasPurchasedTickets) {
            // When the event has purchased tickets, sync the pill visibility
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _syncScrollHintVisibility(event: event);
            });
          } else if (_showScrollHint) {
            // When there are no purchased tickets but the pill was still showing (e.g. tickets removed after refresh, or stale state):
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Hide the pill on the next frame.
              if (mounted) {
                setState(() => _showScrollHint = false);
              }
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShowDetailHero(imageUrl: heroUrl, onShare: () {}),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -25),
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Scrollable body; buy CTA is outside so it is always visible.
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  20,
                                  16,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShowStatusChip(
                                      label: _statusChipLabel(event),
                                    ),
                                    Gap.h16,
                                    AppText.medium(
                                      event.title,
                                      fontSize: 16,
                                      color: AppColors.black,
                                      maxLines: 2,
                                      letterSpacing: -0.4,
                                    ),
                                    Gap.h4,
                                    ShowEventQuickInfoRow(
                                      location: event.location,
                                      dateTimeLine: event.dateTimeLine,
                                    ),
                                    Gap.h16,
                                    ShowAboutEventPanel(
                                      aboutBody: about,
                                      detailDate: detailDate,
                                      detailTime: detailTime,
                                      detailVenue: detailVenue,
                                    ),
                                    if (hasPurchasedTickets) ...[
                                      Gap.h24,
                                      ShowPurchasedTicketsSection(
                                        tickets: event.purchasedTickets,
                                        descriptionFallback:
                                            event.shortDescription
                                                .trim()
                                                .isNotEmpty
                                            ? event.shortDescription
                                            : about,
                                        onViewTickets: (ticket) {
                                          unawaited(
                                            MobileNavigationService.instance
                                                .navigateTo(
                                                  YourTicketsView.path,
                                                  extra: YourTicketsArgs(
                                                    purchasedTicket: ticket,
                                                  ).toRouteExtra(),
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Floated above scroll content; hidden at scroll bottom.
                              if (hasPurchasedTickets && _showScrollHint)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 8,
                                  child: Center(
                                    child: ShowScrollHintPill(
                                      onTap: _scrollToBottom,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Pinned purchase action — does not move with scroll.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: ShowBuyTicket(
                            mainLabel: hasPurchasedTickets
                                ? "Buy more tickets"
                                : "Buy ticket now",
                            availabilityLabel:
                                "(${event.availableTicketsCount} available)",
                            onPressed: () {
                              final eventUid = event.uid;
                              unawaited(
                                MobileNavigationService.instance.navigateTo(
                                  PurchaseTicketsView.path,
                                  extra: {
                                    RoutingArgumentKey.eventUid: eventUid,
                                    RoutingArgumentKey
                                        .onPurchaseSuccess: () async {
                                      await ref
                                          .read(
                                            eventDetailViewModelProvider(
                                              eventUid,
                                            ),
                                          )
                                          .refresh();
                                      await ref
                                          .read(eventsStateProvider)
                                          .fetchBookedEvents();
                                    },
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusChipLabel(EventDetail e) {
    final raw = e.eventStatus.trim();
    if (raw.isNotEmpty) {
      if (raw.length == 1) return raw.toUpperCase();
      return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
    if (e.availableTicketsCount > 0) return "Upcoming";
    return "Sold out";
  }
}
