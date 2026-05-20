import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/tickets/components/show_about_event_panel.dart";
import "package:dth_v4/features/tickets/components/show_buy_ticket.dart";
import "package:dth_v4/features/tickets/components/show_detail_hero.dart";
import "package:dth_v4/features/tickets/components/show_event_quick_info_row.dart";
import "package:dth_v4/features/tickets/components/show_status_chip.dart";
import "package:dth_v4/features/tickets/view_model/event_detail_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
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
        busy: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (Failure failure) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShowDetailHero(
              imageUrl:
                  "https://picsum.photos/seed/${widget.eventUid}/960/540",
              onShare: () {},
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.semiBold(
                        "Could not load event",
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
                      AppButton.primary(
                        text: "Retry",
                        height: 48,
                        press: () => unawaited(vm.refresh()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        idle: () {
          final event = vm.event;
          if (event == null) {
            return const Center(child: CircularProgressIndicator.adaptive());
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
          final canPurchase = event.seatTypes.isNotEmpty;

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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShowStatusChip(label: _statusChipLabel(event)),
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
                          Gap.h16,
                          ShowBuyTicket(
                            availabilityLabel:
                                "(${event.availableTicketsCount} available)",
                            onPressed: canPurchase
                                ? () => unawaited(vm.purchaseTicket())
                                : null,
                          ),
                        ],
                      ),
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
    for (final t in e.purchasedTickets) {
      final raw = t.eventStatus.trim();
      if (raw.isEmpty) continue;
      if (raw.length == 1) return raw.toUpperCase();
      return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
    if (e.availableTicketsCount > 0) return "Upcoming";
    return "Sold out";
  }
}
