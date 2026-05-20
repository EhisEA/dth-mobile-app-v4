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
  });

  final String uid;
  final String title;
  final String shortDescription;
  final String location;
  final String date;
  final String time;

  /// Optional; list endpoints may omit this — UI falls back to placeholder.
  final String? featuredImageUrl;

  /// Booked events include a count; upcoming lists omit it and this stays `0`.
  final String ticketsCount;
  // final int ticketsCount;

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
    );
  }
}
