/// Purchased ticket group on event detail (`purchased_tickets[]`).
///
/// API shape:
/// ```json
/// {
///   "type": "regular",
///   "label": "Regular",
///   "icon_url": "...",
///   "description": "...",
///   "date_purchased": "18 May., 2026 05:52PM",
///   "count": 2,
///   "tickets": [{ "code", "ref", "event_name", "user_name", "date", "time", "location", "type" }]
/// }
/// ```
class PurchasedTicket {
  const PurchasedTicket({
    required this.type,
    required this.label,
    required this.iconUrl,
    required this.description,
    required this.datePurchased,
    required this.count,
    this.tickets = const [],
  });

  final String type;
  final String label;
  final String iconUrl;
  final String description;
  final String datePurchased;
  final int count;
  final List<PurchasedTicketItem> tickets;

  String get displayTitle => label.trim().isNotEmpty ? label.trim() : "Ticket";

  factory PurchasedTicket.fromJson(Map<String, dynamic> json) {
    final ticketsRaw = json["tickets"];
    final tickets = ticketsRaw is List<dynamic>
        ? ticketsRaw
              .map((e) {
                if (e is! Map) return null;
                return PurchasedTicketItem.fromJson(
                  Map<String, dynamic>.from(e),
                );
              })
              .whereType<PurchasedTicketItem>()
              .toList()
        : <PurchasedTicketItem>[];

    return PurchasedTicket(
      type: json["type"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      iconUrl: json["icon_url"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      datePurchased: json["date_purchased"]?.toString() ?? "",
      count: json["count"]?.toInt() ?? 0,
      tickets: tickets,
    );
  }

  Map<String, dynamic> toJson() => {
    "type": type,
    "label": label,
    "icon_url": iconUrl,
    "description": description,
    "date_purchased": datePurchased,
    "count": count,
    "tickets": tickets.map((t) => t.toJson()).toList(),
  };
}

/// Single issued ticket inside [PurchasedTicket.tickets].
class PurchasedTicketItem {
  const PurchasedTicketItem({
    required this.code,
    required this.ref,
    required this.eventName,
    required this.userName,
    required this.date,
    required this.time,
    required this.location,
    required this.type,
  });

  final String code;
  final String ref;
  final String eventName;
  final String userName;
  final String date;
  final String time;
  final String location;
  final String type;

  factory PurchasedTicketItem.fromJson(Map<String, dynamic> json) {
    return PurchasedTicketItem(
      code: json["code"]?.toString() ?? "",
      ref: json["ref"]?.toString() ?? "",
      eventName: json["event_name"]?.toString() ?? "",
      userName: json["user_name"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      time: json["time"]?.toString() ?? "",
      location: json["location"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "code": code,
    "ref": ref,
    "event_name": eventName,
    "user_name": userName,
    "date": date,
    "time": time,
    "location": location,
    "type": type,
  };
}
