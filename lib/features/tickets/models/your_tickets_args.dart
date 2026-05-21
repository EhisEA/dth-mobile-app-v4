import "package:dth_v4/core/router/routing_argument_keys.dart";
import "package:dth_v4/data/data.dart";

/// Navigation payload for [YourTicketsView] — a single [PurchasedTicket] group.
class YourTicketsArgs {
  const YourTicketsArgs({
    required this.purchasedTicket,
    this.eventUid = "",
  });

  final PurchasedTicket purchasedTicket;

  /// Uid of the event this ticket belongs to. Required to produce a Branch
  /// share link; the [PurchasedTicket] payload itself doesn't carry it.
  final String eventUid;

  int get ticketCount => purchasedTicket.count;

  Map<String, dynamic> toRouteExtra() => {
    RoutingArgumentKey.purchasedTicket: purchasedTicket.toJson(),
    RoutingArgumentKey.eventUid: eventUid,
  };

  factory YourTicketsArgs.fromRouteExtra(Map<String, dynamic> extra) {
    final raw =
        extra[RoutingArgumentKey.purchasedTicket] ?? extra["purchasedTicket"];
    final eventUid =
        (extra[RoutingArgumentKey.eventUid] as String?) ?? "";

    if (raw is PurchasedTicket) {
      return YourTicketsArgs(purchasedTicket: raw, eventUid: eventUid);
    }
    if (raw is Map) {
      return YourTicketsArgs(
        purchasedTicket: PurchasedTicket.fromJson(
          Map<String, dynamic>.from(raw),
        ),
        eventUid: eventUid,
      );
    }

    return YourTicketsArgs(
      purchasedTicket: PurchasedTicket.fromJson(extra),
      eventUid: eventUid,
    );
  }
}
