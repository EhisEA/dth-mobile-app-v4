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

/// Server-driven form embedded in a journey card's `meta.form` (e.g. the
/// `info_required` card). Schema only — user input is captured separately,
/// keyed by [InfoFormField.key].
enum InfoFormFieldType {
  text,
  textarea,
  number,
  select,
  unknown;

  static InfoFormFieldType fromRaw(String? raw) {
    switch ((raw ?? "").trim().toLowerCase()) {
      case "text":
        return InfoFormFieldType.text;
      case "textarea":
        return InfoFormFieldType.textarea;
      case "number":
        return InfoFormFieldType.number;
      case "select":
        return InfoFormFieldType.select;
      default:
        return InfoFormFieldType.unknown;
    }
  }
}

class InfoFormField {
  const InfoFormField({
    required this.key,
    required this.type,
    required this.label,
    this.options = const [],
    this.helpText,
    this.required = false,
    this.placeholder,
    this.value,
  });

  final String key;
  final InfoFormFieldType type;
  final String label;
  final List<String> options;
  final String? helpText;
  final bool required;
  final String? placeholder;

  /// Previously-saved answer for this field (`null` when unanswered). May be a
  /// String (text/textarea/select) or a num (number); use [valueAsString] for
  /// text controllers.
  final dynamic value;

  bool get isValid => key.isNotEmpty;

  /// [value] as a display/edit string ("" when unanswered).
  String get valueAsString => value == null ? "" : value.toString();

  factory InfoFormField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json["options"];
    final options = rawOptions is List
        ? rawOptions.map((e) => e.toString()).toList(growable: false)
        : const <String>[];
    return InfoFormField(
      key: json["key"] as String? ?? "",
      type: InfoFormFieldType.fromRaw(json["type"] as String?),
      label: json["label"] as String? ?? "",
      options: options,
      helpText: (json["helpText"] ?? json["help_text"]) as String?,
      required: json["required"] as bool? ?? false,
      placeholder: json["placeholder"] as String?,
      value: json["value"],
    );
  }
}

class InfoFormSection {
  const InfoFormSection({this.title, this.subtitle, required this.rows});

  final String? title;
  final String? subtitle;

  /// 2D layout: a list of rows, each row a list of side-by-side fields.
  final List<List<InfoFormField>> rows;

  /// Flattened fields in render order.
  List<InfoFormField> get fields =>
      rows.expand((r) => r).toList(growable: false);

  factory InfoFormSection.fromJson(Map<String, dynamic> json) {
    final rawRows = json["rows"];
    final rows = <List<InfoFormField>>[];
    if (rawRows is List) {
      for (final row in rawRows) {
        if (row is! List) continue;
        final fields = row
            .whereType<Map>()
            .map((e) => InfoFormField.fromJson(Map<String, dynamic>.from(e)))
            .where((f) => f.isValid)
            .toList(growable: false);
        if (fields.isNotEmpty) rows.add(fields);
      }
    }
    return InfoFormSection(
      title: json["title"] as String?,
      subtitle: json["subtitle"] as String?,
      rows: rows,
    );
  }
}

class InfoFormPage {
  const InfoFormPage({this.title, this.description});

  final String? title;
  final String? description;

  factory InfoFormPage.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const InfoFormPage();
    return InfoFormPage(
      title: json["title"] as String?,
      description: json["description"] as String?,
    );
  }
}

class InfoFormSubmit {
  const InfoFormSubmit({required this.label, required this.variant});

  final String label;
  final String variant;

  factory InfoFormSubmit.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const InfoFormSubmit(label: "Submit", variant: "primary");
    }
    return InfoFormSubmit(
      label: json["label"] as String? ?? "Submit",
      variant: json["variant"] as String? ?? "primary",
    );
  }
}

class InfoFormStep {
  const InfoFormStep({
    required this.key,
    required this.page,
    required this.submit,
    required this.sections,
  });

  final String key;
  final InfoFormPage page;
  final InfoFormSubmit submit;
  final List<InfoFormSection> sections;

  /// Flattened fields across all sections in this step.
  List<InfoFormField> get fields =>
      sections.expand((s) => s.fields).toList(growable: false);

  factory InfoFormStep.fromJson(Map<String, dynamic> json) {
    final rawSections = json["sections"];
    final sections = rawSections is List
        ? rawSections
              .whereType<Map>()
              .map(
                (e) => InfoFormSection.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const <InfoFormSection>[];
    return InfoFormStep(
      key: json["key"] as String? ?? "",
      page: InfoFormPage.fromJson(json["page"] as Map<String, dynamic>?),
      submit: InfoFormSubmit.fromJson(json["submit"] as Map<String, dynamic>?),
      sections: sections,
    );
  }
}

class InfoForm {
  const InfoForm({required this.steps});

  final List<InfoFormStep> steps;

  bool get isEmpty => steps.isEmpty;

  /// Every field across every step, keyed for value capture by [InfoFormField.key].
  List<InfoFormField> get allFields =>
      steps.expand((s) => s.fields).toList(growable: false);

  factory InfoForm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const InfoForm(steps: []);
    final rawSteps = json["steps"];
    final steps = rawSteps is List
        ? rawSteps
              .whereType<Map>()
              .map((e) => InfoFormStep.fromJson(Map<String, dynamic>.from(e)))
              .where((s) => s.sections.isNotEmpty)
              .toList(growable: false)
        : const <InfoFormStep>[];
    return InfoForm(steps: steps);
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
    this.meta,
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
  final Map? meta;

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
      meta: json["meta"] as Map<String, dynamic>?,
    );
  }

  /// Typed view of `meta.form` when present (e.g. the `info_required` card).
  InfoForm? get form {
    final m = meta;
    if (m == null) return null;
    final rawForm = m["form"];
    if (rawForm is Map) {
      final f = InfoForm.fromJson(Map<String, dynamic>.from(rawForm));
      if (!f.isEmpty) return f;
    }
    return null;
  }

  bool get hasDisplayableContent {
    final t = title?.trim() ?? "";
    final b = body?.trim() ?? "";
    final f = footer?.label.trim() ?? "";
    final m = meta?.isNotEmpty ?? false;
    return t.isNotEmpty ||
        b.isNotEmpty ||
        f.isNotEmpty ||
        cta != null ||
        (statusChip != null && !statusChip!.isEmpty) ||
        (progress != null && progress!.isRenderable) ||
        m;
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
