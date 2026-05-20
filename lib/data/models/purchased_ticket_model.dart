class PurchasedTicket {
  const PurchasedTicket({
    required this.seatType,
    required this.description,
    required this.datePurchased,
    required this.count,
    required this.eventStatus,
    required this.entrance,
    required this.eventTime,
  });

  final String seatType;
  final String description;
  final String datePurchased;
  final int count;
  final String eventStatus;
  final String entrance;
  final String eventTime;

  factory PurchasedTicket.fromJson(Map<String, dynamic> json) {
    return PurchasedTicket(
      seatType: json["seat_type"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      datePurchased: json["date_purchased"]?.toString() ?? "",
      count: json["count"],
      eventStatus: json["event_status"]?.toString() ?? "",
      entrance: json["entrance"]?.toString() ?? "",
      eventTime: json["event_time"]?.toString() ?? "",
    );
  }
}
