import "package:dth_v4/core/router/routing_argument_keys.dart";
import "package:dth_v4/data/data.dart";

/// Navigation payload for [YourTicketsView] — a single [PurchasedTicket] group.
class YourTicketsArgs {
  const YourTicketsArgs({required this.purchasedTicket});

  final PurchasedTicket purchasedTicket;

  int get ticketCount => purchasedTicket.count;

  Map<String, dynamic> toRouteExtra() => {
    RoutingArgumentKey.purchasedTicket: purchasedTicket.toJson(),
  };

  factory YourTicketsArgs.fromRouteExtra(Map<String, dynamic> extra) {
    final raw =
        extra[RoutingArgumentKey.purchasedTicket] ?? extra["purchasedTicket"];

    if (raw is PurchasedTicket) {
      return YourTicketsArgs(purchasedTicket: raw);
    }
    if (raw is Map) {
      return YourTicketsArgs(
        purchasedTicket: PurchasedTicket.fromJson(
          Map<String, dynamic>.from(raw),
        ),
      );
    }

    return YourTicketsArgs(
      purchasedTicket: PurchasedTicket.fromJson(extra),
    );
  }
}
