class VotingTutorialItem {
  const VotingTutorialItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  factory VotingTutorialItem.fromJson(Map<String, dynamic> json) {
    return VotingTutorialItem(
      icon: json["icon"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      body: json["body"]?.toString() ?? "",
    );
  }
}

class VotingTutorialStep {
  const VotingTutorialStep({
    required this.heading,
    required this.subtitle,
    required this.sectionLabel,
    required this.ctaLabel,
    required this.items,
  });

  final String heading;
  final String subtitle;
  final String sectionLabel;
  final String ctaLabel;
  final List<VotingTutorialItem> items;

  factory VotingTutorialStep.fromJson(Map<String, dynamic> json) {
    final rawItems = json["items"];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (e) =>
                    VotingTutorialItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const <VotingTutorialItem>[];

    return VotingTutorialStep(
      heading: json["heading"]?.toString() ?? "",
      subtitle: json["subtitle"]?.toString() ?? "",
      sectionLabel: json["section_label"]?.toString() ?? "",
      ctaLabel: json["cta_label"]?.toString() ?? "",
      items: items,
    );
  }
}

class VotingTutorial {
  const VotingTutorial({
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.steps,
  });

  final String title;
  final String body;
  final String ctaLabel;
  final List<VotingTutorialStep> steps;

  bool get hasContent =>
      title.trim().isNotEmpty ||
      body.trim().isNotEmpty ||
      steps.isNotEmpty;

  VotingTutorialStep? get firstStep => steps.isEmpty ? null : steps.first;

  factory VotingTutorial.fromJson(Map<String, dynamic> json) {
    final rawSteps = json["steps"];
    final steps = rawSteps is List
        ? rawSteps
              .whereType<Map>()
              .map(
                (e) =>
                    VotingTutorialStep.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const <VotingTutorialStep>[];

    return VotingTutorial(
      title: json["title"]?.toString() ?? "",
      body: json["body"]?.toString() ?? "",
      ctaLabel: json["cta_label"]?.toString() ?? "",
      steps: steps,
    );
  }
}
