// Models for `GET /applicant/interview-bookings/current` (`data` block).

class InterviewBookingCredentials {
  const InterviewBookingCredentials({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  bool get hasDetails =>
      username.trim().isNotEmpty || password.trim().isNotEmpty;

  factory InterviewBookingCredentials.fromJson(Map<String, dynamic> json) {
    return InterviewBookingCredentials(
      username: json["username"] as String? ?? "",
      password: json["password"] as String? ?? "",
    );
  }
}

class CurrentInterviewBookingCta {
  const CurrentInterviewBookingCta({
    required this.label,
    required this.url,
    this.action = "",
    this.target,
    this.enabled = true,
    this.variant = "primary",
  });

  final String label;
  final String url;
  final String action;
  final String? target;
  final bool enabled;
  final String variant;

  factory CurrentInterviewBookingCta.fromJson(Map<String, dynamic> json) {
    return CurrentInterviewBookingCta(
      label: json["label"] as String? ?? "",
      url: json["url"] as String? ?? "",
      action: json["action"] as String? ?? "",
      target: json["target"] as String?,
      enabled: json["enabled"] as bool? ?? true,
      variant: json["variant"] as String? ?? "primary",
    );
  }
}

class CurrentInterviewBookingPayload {
  const CurrentInterviewBookingPayload({
    required this.title,
    required this.subtitle,
    required this.joinUrl,
    required this.startsAt,
    required this.countdownLabel,
    required this.instructions,
    this.canJoin,
    this.credentials,
    this.cta,
  });

  final String title;
  final String subtitle;

  /// Join URL: API `link` or legacy `join_url`.
  final String joinUrl;
  final DateTime? startsAt;

  /// API `countdown_label` (e.g. "In progress"); empty → derive from [startsAt] / [subtitle] in UI.
  final String countdownLabel;
  final List<String> instructions;
  final bool? canJoin;
  final InterviewBookingCredentials? credentials;
  final CurrentInterviewBookingCta? cta;

  factory CurrentInterviewBookingPayload.fromJson(Map<String, dynamic> json) {
    CurrentInterviewBookingCta? cta;
    final rawCta = json["cta"];
    if (rawCta is Map<String, dynamic>) {
      cta = CurrentInterviewBookingCta.fromJson(rawCta);
    }
    DateTime? startsAt;
    final rawStart = json["starts_at"];
    if (rawStart is String && rawStart.trim().isNotEmpty) {
      startsAt = DateTime.tryParse(rawStart.trim());
    }
    final rawLink = json["link"];
    final rawJoinUrl = json["join_url"];
    final url = (rawLink is String && rawLink.trim().isNotEmpty)
        ? rawLink.trim()
        : (rawJoinUrl is String ? rawJoinUrl.trim() : "");

    final instructions = <String>[];
    final rawInstr = json["instructions"];
    if (rawInstr is List) {
      for (final e in rawInstr) {
        if (e is String && e.trim().isNotEmpty) {
          instructions.add(e.trim());
        }
      }
    }

    final rawCanJoin = json["can_join"];
    final bool? canJoin = rawCanJoin is bool ? rawCanJoin : null;

    InterviewBookingCredentials? credentials;
    final rawCred = json["credentials"];
    if (rawCred is Map<String, dynamic>) {
      final c = InterviewBookingCredentials.fromJson(rawCred);
      if (c.hasDetails) credentials = c;
    }

    return CurrentInterviewBookingPayload(
      title: json["title"] as String? ?? "",
      subtitle: json["subtitle"] as String? ?? "",
      joinUrl: url,
      startsAt: startsAt,
      countdownLabel: json["countdown_label"] as String? ?? "",
      instructions: instructions,
      canJoin: canJoin,
      credentials: credentials,
      cta: cta,
    );
  }
}
