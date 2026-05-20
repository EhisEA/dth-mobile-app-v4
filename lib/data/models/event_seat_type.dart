/// Seat type offered for an event (when API includes `seat_types`).
class EventSeatType {
  const EventSeatType({required this.uid, required this.name});

  final String uid;
  final String name;

  factory EventSeatType.fromJson(Map<String, dynamic> json) {
    return EventSeatType(
      uid: json["uid"]?.toString() ?? "",
      name: json["name"]?.toString() ?? json["label"]?.toString() ?? "",
    );
  }
}
