// Models for `GET /applicant/schedule` (`data` block).

import "package:dth_v4/data/models/applicant_dashboard_models.dart";

class ScheduleEvent {
  const ScheduleEvent({
    required this.icon,
    required this.variant,
    required this.title,
    required this.body,
    required this.date,
    required this.time,
    this.cta,
  });

  final String icon;
  final String variant;
  final String title;
  final String body;
  final String date;
  final String time;
  final JourneyCta? cta;

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    JourneyCta? cta;
    final rawCta = json["cta"];
    if (rawCta is Map<String, dynamic>) {
      cta = JourneyCta.fromJson(rawCta);
      if (cta.isEmpty) cta = null;
    }
    return ScheduleEvent(
      icon: json["icon"] as String? ?? "",
      variant: json["variant"] as String? ?? "",
      title: json["title"] as String? ?? "",
      body: json["body"] as String? ?? "",
      date: json["date"] as String? ?? "",
      time: json["time"] as String? ?? "",
      cta: cta,
    );
  }
}

class ApplicantSchedulePayload {
  const ApplicantSchedulePayload({required this.title, required this.events});

  final String title;
  final List<ScheduleEvent> events;

  factory ApplicantSchedulePayload.fromJson(Map<String, dynamic> json) {
    final rawEvents = json["events"] as List<dynamic>? ?? const [];
    return ApplicantSchedulePayload(
      title: json["title"] as String? ?? "",
      events: rawEvents
          .map(
            (e) => ScheduleEvent.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}
