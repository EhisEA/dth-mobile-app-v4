import "package:dth_v4/data/models/event_seat_type.dart";
import "package:dth_v4/data/models/purchased_ticket_model.dart";

class EventDetail {
  const EventDetail({
    required this.uid,
    required this.title,
    required this.featuredImageUrl,
    required this.shortDescription,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.dateFull,
    required this.availableTicketsCount,
    required this.purchasedTickets,
    required this.seatTypes,
  });

  final String uid;
  final String title;
  final String featuredImageUrl;
  final String shortDescription;
  final String description;
  final String location;
  final String date;
  final String time;
  final String dateFull;
  final int availableTicketsCount;
  final List<PurchasedTicket> purchasedTickets;
  final List<EventSeatType> seatTypes;

  String get dateTimeLine => "$date $time".trim();

  String get heroImageUrl =>
      featuredImageUrl.trim().isNotEmpty ? featuredImageUrl.trim() : "";

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    final availRaw = json["available_tickets_count"];
    final available = availRaw is int
        ? availRaw
        : availRaw is num
        ? availRaw.toInt()
        : 0;

    final purchased = json["purchased_tickets"];
    final purchasedList = purchased is List<dynamic>
        ? purchased
              .map((e) {
                if (e is! Map) return null;
                return PurchasedTicket.fromJson(
                  Map<String, dynamic>.from(e),
                );
              })
              .whereType<PurchasedTicket>()
              .toList()
        : <PurchasedTicket>[];

    final seatTypesRaw = json["seat_types"];
    final seatTypes = seatTypesRaw is List<dynamic>
        ? seatTypesRaw
              .map((e) {
                if (e is! Map) return null;
                return EventSeatType.fromJson(Map<String, dynamic>.from(e));
              })
              .whereType<EventSeatType>()
              .where((s) => s.uid.isNotEmpty)
              .toList()
        : <EventSeatType>[];

    return EventDetail(
      uid: json["uid"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      featuredImageUrl: json["featured_image_url"]?.toString() ?? "",
      shortDescription: json["short_description"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      location: json["location"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      time: json["time"]?.toString() ?? "",
      dateFull: json["date_full"]?.toString() ?? "",
      availableTicketsCount: available,
      purchasedTickets: purchasedList,
      seatTypes: seatTypes,
    );
  }
}
