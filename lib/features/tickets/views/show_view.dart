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
import "package:flutter/rendering.dart";
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
  /// How much of the purchased-tickets section must be on screen before it
  /// counts as "seen" and the scroll-hint pill is hidden.
  static const double _firstTicketRevealTolerancePx = 40;

  /// Scrolls event details + purchased tickets; buy CTA is pinned below this.
  late final ScrollController _scrollController;

  /// Anchors visibility checks for [ShowPurchasedTicketsSection].
  final GlobalKey _purchasedTicketsSectionKey = GlobalKey();

  /// Whether the floating "View your tickets" scroll-hint pill is visible.
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

  // True when the user has scrolled far enough that purchased tickets are on screen.
  bool _hasScrolledToFirstPurchasedTicket() {
    // Need the section widget and a live scroll position before we can measure.
    final sectionContext = _purchasedTicketsSectionKey.currentContext;
    // hasClients means the ScrollController is attached to a scrollable widget right now
    if (sectionContext == null || !_scrollController.hasClients) {
      return false;
    }

    final box = sectionContext.findRenderObject() as RenderBox?;
    // Section not laid out yet — treat as not reached so the pill can show after paint.
    // If we can’t measure the purchased-tickets block yet, treat it as not reached and don’t hide the pill based on bad data.
    // we can measure the purchased-tickets block after layout has run, event is loaded, section is laid out and GlobalKey is
    // attached i.e _purchasedTicketsSectionKey.currentContext is non-null (the section widget exists).
    if (box == null || !box.hasSize || !box.attached) return false;

    // The scrollable ancestor of purchased tickets (our SingleChildScrollView).
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return false;

    final position = _scrollController.position;

    // getOffsetToReveal: scroll offset needed to bring [box] into view.
    // alignment 0 = align the top of the section with the top of the viewport.
    final revealOffset = viewport.getOffsetToReveal(box, 0).offset;

    // The section's top edge enters the viewport from the bottom once we've
    // scrolled to (revealOffset - viewportDimension). We don't want to wait for
    // it to reach the *top* of the viewport — as soon as the user can see it,
    // the pill is redundant. Add the tolerance so a meaningful slice of the
    // section is on screen before we hide the pill.
    final seenThreshold =
        revealOffset -
        position.viewportDimension +
        _firstTicketRevealTolerancePx;
    return position.pixels >= seenThreshold;
  }

  // Called every time the user scrolls (or when scroll position changes, e.g. after tapping the pill).
  void _onScroll() => _syncScrollHintVisibility();

  // Show or hide the "View your tickets" pill based on scroll and purchased tickets.
  void _syncScrollHintVisibility({EventDetail? event}) {
    if (!mounted) return;

    // Get event from the view model, or use the one passed in after layout.
    final detail =
        event ?? ref.read(eventDetailViewModelProvider(widget.eventUid)).event;
    // Show pill only when there are tickets and the section is still below the fold.
    final next =
        detail != null &&
        detail.purchasedTickets.isNotEmpty &&
        !_hasScrolledToFirstPurchasedTicket();
    // Scroll back up → section off-screen again → pill comes back.
    if (next != _showScrollHint) {
      setState(() => _showScrollHint = next);
    }
  }

  // Pill tap: scroll to purchased tickets; buy button stays pinned below.
  void _scrollToFirstPurchasedTicket() {
    final sectionContext = _purchasedTicketsSectionKey.currentContext;
    if (sectionContext == null) return;
    unawaited(
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        alignment: 0,
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
          // _hasScrolledToFirstPurchasedTicket() needs the purchased-tickets section laid out.
          // In build() the section is not measured yet, and setState is not allowed.
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
                                      fontSize: 18,
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
                                        key: _purchasedTicketsSectionKey,
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
                              // Floated above scroll content; hidden while first ticket is in view.
                              if (hasPurchasedTickets && _showScrollHint)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 8,
                                  child: Center(
                                    child: ShowScrollHintPill(
                                      onTap: _scrollToFirstPurchasedTicket,
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
