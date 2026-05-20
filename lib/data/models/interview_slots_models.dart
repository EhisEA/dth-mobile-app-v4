// Models for `GET /applicant/interview-slots` (no query/body) and booking confirmation.

class InterviewPickerDate {
  const InterviewPickerDate({
    required this.date,
    required this.label,
    required this.selected,
    required this.available,
  });

  final String date;
  final String label;
  final bool selected;
  final bool available;

  factory InterviewPickerDate.fromJson(Map<String, dynamic> json) {
    return InterviewPickerDate(
      date: json["date"] as String? ?? "",
      label: json["label"] as String? ?? "",
      selected: json["selected"] as bool? ?? false,
      available: json["available"] as bool? ?? true,
    );
  }
}

class InterviewPickerTimeSlot {
  const InterviewPickerTimeSlot({
    required this.time,
    required this.label,
    required this.slotUid,
    required this.selected,
    required this.available,
  });

  final String time;
  final String label;
  final String slotUid;
  final bool selected;
  final bool available;

  factory InterviewPickerTimeSlot.fromJson(Map<String, dynamic> json) {
    return InterviewPickerTimeSlot(
      time: json["time"] as String? ?? "",
      label: json["label"] as String? ?? "",
      slotUid: json["slot_uid"] as String? ?? "",
      selected: json["selected"] as bool? ?? false,
      available: json["available"] as bool? ?? true,
    );
  }
}

class InterviewPickerSubmit {
  const InterviewPickerSubmit({
    required this.label,
    required this.action,
    required this.enabled,
    required this.variant,
  });

  final String label;
  final String action;
  final bool enabled;
  final String variant;

  factory InterviewPickerSubmit.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const InterviewPickerSubmit(
        label: "Submit",
        action: "submit",
        enabled: false,
        variant: "primary",
      );
    }
    return InterviewPickerSubmit(
      label: json["label"] as String? ?? "Submit",
      action: json["action"] as String? ?? "",
      enabled: json["enabled"] as bool? ?? false,
      variant: json["variant"] as String? ?? "primary",
    );
  }
}

class InterviewPickerEmptyState {
  const InterviewPickerEmptyState({this.title, this.body});

  final String? title;
  final String? body;

  bool get hasContent {
    final t = title?.trim() ?? "";
    final b = body?.trim() ?? "";
    return t.isNotEmpty || b.isNotEmpty;
  }

  factory InterviewPickerEmptyState.fromJson(Object? raw) {
    if (raw == null || raw is! Map<String, dynamic>) {
      return const InterviewPickerEmptyState();
    }
    final msg = raw["message"] as String? ?? raw["body"] as String?;
    return InterviewPickerEmptyState(title: raw["title"] as String?, body: msg);
  }
}

/// Payload for the interview picker bottom sheet (`data` from GET interview-slots).
class InterviewPickerData {
  const InterviewPickerData({
    required this.title,
    required this.subtitle,
    required this.dates,
    required this.times,
    required this.submit,
    this.emptyState,
  });

  final String title;
  final String subtitle;
  final List<InterviewPickerDate> dates;
  final List<InterviewPickerTimeSlot> times;
  final InterviewPickerSubmit submit;
  final InterviewPickerEmptyState? emptyState;

  factory InterviewPickerData.fromJson(Map<String, dynamic> json) {
    final rawDates = json["dates"] as List<dynamic>? ?? const [];
    final rawTimes = json["times"] as List<dynamic>? ?? const [];
    return InterviewPickerData(
      title: json["title"] as String? ?? "",
      subtitle: json["subtitle"] as String? ?? "",
      dates: rawDates
          .map(
            (e) => InterviewPickerDate.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      times: rawTimes
          .map(
            (e) => InterviewPickerTimeSlot.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      submit: InterviewPickerSubmit.fromJson(
        json["submit"] as Map<String, dynamic>?,
      ),
      emptyState: _parseEmptyState(json["empty_state"]),
    );
  }

  static InterviewPickerEmptyState? _parseEmptyState(Object? raw) {
    final es = InterviewPickerEmptyState.fromJson(raw);
    return es.hasContent ? es : null;
  }
}

/// `data` from POST interview-bookings success response.
class InterviewBookingConfirmation {
  const InterviewBookingConfirmation({
    required this.title,
    required this.subtitle,
    this.ctaLabel,
  });

  final String title;
  final String subtitle;
  final String? ctaLabel;

  factory InterviewBookingConfirmation.fromJson(Map<String, dynamic> json) {
    String? ctaLabel;
    final rawCta = json["cta"];
    if (rawCta is Map<String, dynamic>) {
      ctaLabel = rawCta["label"] as String?;
    }
    return InterviewBookingConfirmation(
      title: json["title"] as String? ?? "",
      subtitle: json["subtitle"] as String? ?? "",
      ctaLabel: ctaLabel,
    );
  }
}
