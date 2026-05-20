// Response models for `GET /applicant/dashboard`.
// Tolerant of minor backend shape differences (optional keys, two status_chip styles).

class ApplicantSeasonInfo {
  const ApplicantSeasonInfo({
    required this.uid,
    required this.name,
    this.status,
    this.stageLabel,
  });

  final String uid;
  final String name;
  final String? status;
  final String? stageLabel;

  factory ApplicantSeasonInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ApplicantSeasonInfo(uid: "", name: "");
    }
    return ApplicantSeasonInfo(
      uid: json["uid"] as String? ?? "",
      name: json["name"] as String? ?? "",
      status: json["status"] as String?,
      stageLabel: json["stage_label"] as String?,
    );
  }
}

class ApplicantDashboardHeader {
  const ApplicantDashboardHeader({this.title, this.backAction});

  final String? title;
  final String? backAction;

  factory ApplicantDashboardHeader.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ApplicantDashboardHeader();
    return ApplicantDashboardHeader(
      title: json["title"] as String?,
      backAction: json["back_action"] as String?,
    );
  }
}

class ApplicantPerformanceInfo {
  const ApplicantPerformanceInfo({
    required this.score,
    required this.max,
    required this.color,
    required this.label,
    this.caption,
  });

  final int score;
  final int max;
  final String color;
  final String label;
  final String? caption;

  int get percent {
    if (max <= 0) return 0;
    return ((score / max) * 100).round().clamp(0, 100);
  }

  factory ApplicantPerformanceInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ApplicantPerformanceInfo(
        score: 0,
        max: 100,
        color: "neutral",
        label: "Performance Score",
        caption: "Based on reviewer evaluations",
      );
    }
    final rawScore = json["score"];
    final score = rawScore is num ? rawScore.round() : 0;
    final rawMax = json["max"];
    final max = rawMax is num ? rawMax.round() : 100;
    return ApplicantPerformanceInfo(
      score: score,
      max: max > 0 ? max : 100,
      color: json["color"] as String? ?? "neutral",
      label: json["label"] as String? ?? "Performance Score",
      caption: json["caption"] as String?,
    );
  }
}

class ApplicantDashboardBanner {
  /// Inline footer card (`footer_banner` JSON). For the top hero image block,
  /// use [ApplicantDashboardHeroBanner] on [ApplicantDashboardData.banner].
  const ApplicantDashboardBanner({
    required this.variant,
    this.title,
    required this.body,
  });

  final String variant;
  final String? title;
  final String body;

  factory ApplicantDashboardBanner.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ApplicantDashboardBanner(variant: "", body: "");
    }
    return ApplicantDashboardBanner(
      variant: json["variant"] as String? ?? "",
      title: json["title"] as String?,
      body: json["body"] as String? ?? "",
    );
  }

  bool get isEmpty {
    final t = title?.trim() ?? "";
    final b = body.trim();
    return t.isEmpty && b.isEmpty;
  }
}

class JourneyStatusChip {
  const JourneyStatusChip({
    required this.label,
    this.variant,
    this.tone,
    this.icon,
  });

  final String label;
  final String? variant;
  final String? tone;
  final String? icon;

  factory JourneyStatusChip.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const JourneyStatusChip(label: "");
    }
    return JourneyStatusChip(
      label: json["label"] as String? ?? "",
      variant: json["variant"] as String?,
      tone: json["tone"] as String?,
      icon: json["icon"] as String?,
    );
  }

  bool get isEmpty => label.isEmpty;
}

/// Journey card `footer` object: `{ "label": "...", "tone": "danger" | "success" }`.
/// Legacy payloads may send `footer` as a plain string.
class JourneyCardFooter {
  const JourneyCardFooter({required this.label, this.tone});

  final String label;
  final String? tone;

  bool get isEmpty => label.trim().isEmpty;

  factory JourneyCardFooter.fromJson(Map<String, dynamic> json) {
    return JourneyCardFooter(
      label: json["label"] as String? ?? "",
      tone: json["tone"] as String?,
    );
  }

  /// Plain string footer (no tone).
  factory JourneyCardFooter.plain(String text) {
    return JourneyCardFooter(label: text, tone: null);
  }
}

class JourneyProgress {
  const JourneyProgress({
    required this.type,
    required this.value,
    required this.max,
    required this.label,
    required this.color,
  });

  final String type;
  final int value;
  final int max;
  final String label;
  final String color;

  String get typeNormalized => type.trim().toLowerCase();

  bool get isRenderable {
    final t = typeNormalized;
    return t == "bar" || t == "stars" || t == "gauge";
  }

  factory JourneyProgress.fromJson(Map<String, dynamic> json) {
    final rawValue = json["value"];
    final value = rawValue is num ? rawValue.round() : 0;
    final rawMax = json["max"];
    final max = rawMax is num ? rawMax.round() : 0;
    return JourneyProgress(
      type: json["type"] as String? ?? "",
      value: value,
      max: max,
      label: json["label"] as String? ?? "",
      color: json["color"] as String? ?? "neutral",
    );
  }
}

class JourneyCta {
  const JourneyCta({
    required this.label,
    required this.action,
    required this.target,
    required this.enabled,
    required this.variant,
    this.isLoading = false,
  });

  final String label;
  final String action;
  final String target;
  final bool enabled;
  final String variant;
  final bool isLoading;

  factory JourneyCta.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const JourneyCta(
        label: "",
        action: "",
        target: "",
        enabled: false,
        variant: "primary",
      );
    }
    final rawLoading = json["is_loading"] ?? json["isLoading"];
    final loading = rawLoading is bool ? rawLoading : false;
    return JourneyCta(
      label: json["label"] as String? ?? "",
      action: json["action"] as String? ?? "",
      target: json["target"] as String? ?? "",
      enabled: json["enabled"] as bool? ?? false,
      variant: json["variant"] as String? ?? "primary",
      isLoading: loading,
    );
  }

  bool get isEmpty => label.isEmpty;
}

/// Top-of-dashboard hero (`banner` JSON): image-backed card with title/body and
/// optional CTA. Distinct from [ApplicantDashboardBanner], which is used for
/// [ApplicantDashboardData.footerBanner] only.
class ApplicantDashboardHeroBanner {
  const ApplicantDashboardHeroBanner({
    required this.variant,
    this.title,
    required this.body,
    this.cta,
  });

  final String variant;
  final String? title;
  final String body;
  final JourneyCta? cta;

  factory ApplicantDashboardHeroBanner.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ApplicantDashboardHeroBanner(variant: "", body: "");
    }
    JourneyCta? cta;
    final rawCta = json["cta"];
    if (rawCta is Map<String, dynamic>) {
      final c = JourneyCta.fromJson(rawCta);
      if (!c.isEmpty) cta = c;
    }
    return ApplicantDashboardHeroBanner(
      variant: json["variant"] as String? ?? "",
      title: json["title"] as String?,
      body: json["body"] as String? ?? "",
      cta: cta,
    );
  }

  bool get isEmpty {
    final t = title?.trim() ?? "";
    final b = body.trim();
    return t.isEmpty && b.isEmpty;
  }
}

class JourneyCard {
  const JourneyCard({
    required this.key,
    required this.order,
    required this.visible,
    this.title,
    this.subtitle,
    this.body,
    this.statusChip,
    this.cta,
    this.progress,
    this.footer,
  });

  final String key;
  final int order;
  final bool visible;
  final String? title;
  final String? subtitle;
  final String? body;
  final JourneyStatusChip? statusChip;
  final JourneyCta? cta;
  final JourneyProgress? progress;
  final JourneyCardFooter? footer;

  factory JourneyCard.fromJson(Map<String, dynamic> json) {
    JourneyStatusChip? chip;
    final rawChip = json["status_chip"];
    if (rawChip is Map<String, dynamic>) {
      chip = JourneyStatusChip.fromJson(rawChip);
      if (chip.isEmpty) chip = null;
    }

    JourneyCta? cta;
    final rawCta = json["cta"];
    if (rawCta is Map<String, dynamic>) {
      cta = JourneyCta.fromJson(rawCta);
      if (cta.isEmpty) cta = null;
    }

    JourneyProgress? progress;
    final rawProgress = json["progress"];
    if (rawProgress is Map<String, dynamic>) {
      final p = JourneyProgress.fromJson(rawProgress);
      if (p.type.trim().isNotEmpty) progress = p;
    }

    JourneyCardFooter? footer;
    final rawFooter = json["footer"];
    if (rawFooter is String) {
      final s = rawFooter.trim();
      if (s.isNotEmpty) footer = JourneyCardFooter.plain(s);
    } else if (rawFooter is Map<String, dynamic>) {
      final f = JourneyCardFooter.fromJson(rawFooter);
      if (!f.isEmpty) footer = f;
    }

    final rawOrder = json["order"];
    final order = rawOrder is num ? rawOrder.toInt() : 0;

    return JourneyCard(
      key: json["key"] as String? ?? "",
      order: order,
      visible: json["visible"] as bool? ?? false,
      title: json["title"] as String?,
      subtitle: json["subtitle"] as String?,
      body: json["body"] as String?,
      statusChip: chip,
      cta: cta,
      progress: progress,
      footer: footer,
    );
  }

  bool get hasDisplayableContent {
    final t = title?.trim() ?? "";
    final b = body?.trim() ?? "";
    final f = footer?.label.trim() ?? "";
    return t.isNotEmpty ||
        b.isNotEmpty ||
        f.isNotEmpty ||
        cta != null ||
        (statusChip != null && !statusChip!.isEmpty) ||
        (progress != null && progress!.isRenderable);
  }
}

class ApplicantJourneySection {
  const ApplicantJourneySection({this.title, this.stage, required this.cards});

  final String? title;
  final String? stage;
  final List<JourneyCard> cards;

  factory ApplicantJourneySection.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ApplicantJourneySection(cards: []);
    }
    final rawCards = json["cards"] as List<dynamic>? ?? const [];
    final cards = rawCards
        .map((e) => JourneyCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return ApplicantJourneySection(
      title: json["title"] as String?,
      stage: json["stage"] as String?,
      cards: cards,
    );
  }

  /// Visible cards with enough content to render, sorted by [order].
  List<JourneyCard> get displayCards {
    final list = cards
        .where((c) => c.visible && c.hasDisplayableContent)
        .toList(growable: false);
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
}

class ApplicantDashboardData {
  final ApplicantSeasonInfo season;
  final ApplicantDashboardHeader? header;
  final ApplicantPerformanceInfo performance;
  final ApplicantDashboardHeroBanner? banner;
  final ApplicantDashboardBanner? footerBanner;
  final ApplicantJourneySection journey;
  final Map<String, String> actions;

  const ApplicantDashboardData({
    required this.season,
    this.header,
    required this.performance,
    this.banner,
    this.footerBanner,
    required this.journey,
    required this.actions,
  });
  factory ApplicantDashboardData.fromJson(Map<String, dynamic> json) {
    final rawActions = json["actions"];
    final actions = <String, String>{};
    if (rawActions is Map) {
      rawActions.forEach((k, v) {
        if (k != null && v != null) {
          actions[k.toString()] = v.toString();
        }
      });
    }

    ApplicantDashboardHeroBanner? banner;
    final rawBanner = json["banner"];
    if (rawBanner is Map<String, dynamic>) {
      final b = ApplicantDashboardHeroBanner.fromJson(rawBanner);
      if (!b.isEmpty) banner = b;
    }

    ApplicantDashboardBanner? footer;
    final rawFooter = json["footer_banner"];
    if (rawFooter is Map<String, dynamic>) {
      final f = ApplicantDashboardBanner.fromJson(rawFooter);
      if (!f.isEmpty) footer = f;
    }

    return ApplicantDashboardData(
      season: ApplicantSeasonInfo.fromJson(
        json["season"] as Map<String, dynamic>?,
      ),
      header: _parseHeader(json["header"]),
      performance: ApplicantPerformanceInfo.fromJson(
        json["performance"] as Map<String, dynamic>?,
      ),
      banner: banner,
      footerBanner: footer,
      journey: ApplicantJourneySection.fromJson(
        json["journey"] as Map<String, dynamic>?,
      ),
      actions: actions,
    );
  }

  static ApplicantDashboardHeader? _parseHeader(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return ApplicantDashboardHeader.fromJson(raw);
    }
    return null;
  }
}
