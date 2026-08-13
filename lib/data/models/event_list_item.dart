class EventListItem {
  const EventListItem({
    required this.uid,
    required this.title,
    required this.shortDescription,
    required this.location,
    required this.date,
    required this.time,
    this.featuredImageUrl,
    this.ticketsCount = "0",
    this.ticketsLeft,
    this.ticketsOwned,
  });

  final String uid;
  final String title;
  final String shortDescription;
  final String location;
  final String date;
  final String time;

  /// Optional; list endpoints may omit this — UI falls back to placeholder.
  final String? featuredImageUrl;

  /// Legacy booked count string; prefer [ticketsOwned] when present.
  final String ticketsCount;

  /// Remaining tickets for upcoming events (`tickets_left`).
  final int? ticketsLeft;

  /// Tickets the user owns for purchased events (`tickets_owned`).
  final int? ticketsOwned;

  String get displayImageUrl => featuredImageUrl ?? "";

  String get dateTimeLine => "$date $time";

  factory EventListItem.fromJson(Map<String, dynamic> json) {
    return EventListItem(
      uid: json["uid"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      shortDescription: json["short_description"]?.toString() ?? "",
      location: json["location"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      time: json["time"]?.toString() ?? "",
      featuredImageUrl: json["featured_image_url"]?.toString(),
      ticketsCount: json["tickets_count"]?.toString() ?? "0",
      ticketsLeft: _parseOptionalInt(json["tickets_left"]),
      ticketsOwned: _parseOptionalInt(json["tickets_owned"]),
    );
  }

  static int? _parseOptionalInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }
}
