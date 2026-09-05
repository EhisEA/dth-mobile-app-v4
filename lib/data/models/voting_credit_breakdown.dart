import "package:flutter/material.dart";

class VotingCreditBreakdown {
  const VotingCreditBreakdown({
    required this.title,
    required this.available,
    required this.availableLabel,
    required this.segments,
    required this.sections,
  });

  final String title;
  final int available;
  final String availableLabel;
  final List<VotingCreditSegment> segments;
  final List<VotingCreditSection> sections;

  factory VotingCreditBreakdown.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return VotingCreditBreakdown.empty;
    }
    final segmentsRaw = json["segments"];
    final sectionsRaw = json["sections"];
    return VotingCreditBreakdown(
      title: _stringField(json["title"], fallback: "Breakdown"),
      available: _asInt(json["available"]),
      availableLabel: _stringField(
        json["available_label"],
        fallback: "${_asInt(json["available"])} available",
      ),
      segments: segmentsRaw is List
          ? segmentsRaw
                .whereType<Map>()
                .map(
                  (e) => VotingCreditSegment.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
      sections: sectionsRaw is List
          ? sectionsRaw
                .whereType<Map>()
                .map(
                  (e) => VotingCreditSection.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "available": available,
    "available_label": availableLabel,
    "segments": segments.map((s) => s.toJson()).toList(),
    "sections": sections.map((s) => s.toJson()).toList(),
  };

  static const empty = VotingCreditBreakdown(
    title: "Breakdown",
    available: 0,
    availableLabel: "0 available",
    segments: [],
    sections: [],
  );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  static String _stringField(dynamic value, {required String fallback}) {
    final text = value?.toString().trim() ?? "";
    return text.isEmpty ? fallback : text;
  }
}

class VotingCreditSegment {
  const VotingCreditSegment({
    required this.key,
    required this.label,
    required this.amount,
    required this.colorKey,
  });

  final String key;
  final String label;
  final int amount;
  final String colorKey;

  Color get color => VotingCreditPalette.colorFor(colorKey);

  Gradient? get gradient => VotingCreditPalette.gradientFor(colorKey);

  Color get insetShadowColor => VotingCreditPalette.insetShadowFor(colorKey);

  factory VotingCreditSegment.fromJson(Map<String, dynamic> json) {
    return VotingCreditSegment(
      key: json["key"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      amount: VotingCreditBreakdown._asInt(json["amount"]),
      colorKey: json["color"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "key": key,
    "label": label,
    "amount": amount,
    "color": colorKey,
  };
}

class VotingCreditSection {
  const VotingCreditSection({
    required this.key,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.colorKey,
  });

  final String key;
  final String title;
  final String description;
  final String iconKey;
  final String colorKey;

  Color get color => VotingCreditPalette.colorFor(colorKey);

  Color get backgroundColor => VotingCreditPalette.backgroundFor(colorKey);

  factory VotingCreditSection.fromJson(Map<String, dynamic> json) {
    return VotingCreditSection(
      key: json["key"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      iconKey: json["icon"]?.toString() ?? "",
      colorKey: json["color"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "key": key,
    "title": title,
    "description": description,
    "icon": iconKey,
    "color": colorKey,
  };
}

abstract final class VotingCreditPalette {
  static const Color subscription = Color(0xff00AD55);
  static const Color subscriptionDark = Color(0xff018A44);
  static const Color subscriptionInsetShadow = Color(0xff18D877);
  static const Color purchased = Color(0xffFDDA38);
  static const Color purchasedInsetShadow = Color(0xffF8CD0A);
  static const Color subscriptionBg = Color(0xffE5FBF0);
  static const Color purchasedBg = Color(0xffFFF4E5);

  /// Shared rail behind subscription + purchased section icons.
  static const LinearGradient sectionsRailGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xffE5FBF0), Color(0xffF5FDFC), Color(0xffFBF8E5)],
  );

  /// Subscription green linear gradient (`#00AD55` → `#018A44`).
  static const LinearGradient subscriptionGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [subscription, subscriptionDark],
  );

  static Color colorFor(String raw) {
    switch (raw.trim().toLowerCase()) {
      case "green":
        return subscription;
      case "yellow":
        return purchased;
      default:
        return subscription;
    }
  }

  static Gradient? gradientFor(String raw) {
    switch (raw.trim().toLowerCase()) {
      case "green":
        return subscriptionGradient;
      default:
        return null;
    }
  }

  /// Inner shadow color from Figma (y: 4, blur: 7).
  static Color insetShadowFor(String raw) {
    switch (raw.trim().toLowerCase()) {
      case "green":
        return subscriptionInsetShadow;
      case "yellow":
        return purchasedInsetShadow;
      default:
        return subscriptionInsetShadow;
    }
  }

  static Color backgroundFor(String raw) {
    switch (raw.trim().toLowerCase()) {
      case "green":
        return subscriptionBg;
      case "yellow":
        return purchasedBg;
      default:
        return subscriptionBg;
    }
  }
}
