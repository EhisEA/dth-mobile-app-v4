class SponsorshipSponsor {
  const SponsorshipSponsor({
    required this.uid,
    required this.label,
    required this.name,
    required this.prefix,
    required this.color,
    required this.url,
    required this.logo,
    required this.image,
    this.width,
    this.height,
  });

  final String uid;
  final String label;
  final String name;
  final String? prefix;
  final String color;
  final String url;
  final String logo;
  final String image;
  final double? width;
  final double? height;

  bool get hasLogo => logo.trim().isNotEmpty;

  bool get hasImage => image.trim().isNotEmpty;

  factory SponsorshipSponsor.fromJson(Map<String, dynamic> json) {
    return SponsorshipSponsor(
      uid: json["uid"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      prefix: json["prefix"]?.toString(),
      color: json["color"]?.toString() ?? "",
      url: json["url"]?.toString() ?? "",
      logo: json["logo"]?.toString() ?? "",
      image: json["image"]?.toString() ?? "",
      width: _asPositiveDouble(json["width"]),
      height: _asPositiveDouble(json["height"]),
    );
  }

  static double? _asPositiveDouble(dynamic value) {
    if (value is num) {
      final n = value.toDouble();
      return n > 0 ? n : null;
    }
    final parsed = double.tryParse(value?.toString() ?? "");
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}

class SponsorshipSection {
  const SponsorshipSection({
    required this.label,
    required this.name,
    required this.prefix,
    required this.instructions,
    required this.sponsors,
  });

  final String label;
  final String name;
  final String prefix;
  final List<String> instructions;
  final List<SponsorshipSponsor> sponsors;

  bool get hasSponsors => sponsors.isNotEmpty;

  factory SponsorshipSection.fromJson(Map<String, dynamic> json) {
    final rawSponsors = json["sponsors"];
    final sponsors = rawSponsors is List
        ? rawSponsors
              .whereType<Map>()
              .map(
                (e) =>
                    SponsorshipSponsor.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const <SponsorshipSponsor>[];

    final rawInstructions = json["instructions"];
    final instructions = rawInstructions is List
        ? rawInstructions.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    return SponsorshipSection(
      label: json["label"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      prefix: json["prefix"]?.toString() ?? "",
      instructions: instructions,
      sponsors: sponsors,
    );
  }
}

class SponsorshipsData {
  const SponsorshipsData({required this.sections});

  final Map<String, SponsorshipSection> sections;

  SponsorshipSection? get voting => sections["voting"];

  SponsorshipSection? get poll => sections["poll"];

  SponsorshipSection? get ticket => sections["ticket"];

  SponsorshipSection? section(String name) => sections[name];

  factory SponsorshipsData.fromJson(Map<String, dynamic> json) {
    final sections = <String, SponsorshipSection>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final section = SponsorshipSection.fromJson(
        Map<String, dynamic>.from(value),
      );
      sections[entry.key] = section;
    }
    return SponsorshipsData(sections: Map.unmodifiable(sections));
  }

  static const empty = SponsorshipsData(sections: {});
}
