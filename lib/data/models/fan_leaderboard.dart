class FanLeaderboardEntry {
  const FanLeaderboardEntry({
    required this.rank,
    required this.name,
    this.avatar,
    required this.points,
    this.isYou = false,
  });

  final int rank;
  final String name;
  final String? avatar;
  final int points;
  final bool isYou;

  factory FanLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return FanLeaderboardEntry(
      rank: _asInt(json["rank"]),
      name: json["name"]?.toString() ?? "",
      avatar: _nullableString(json["avatar"]),
      points: _asInt(json["points"]),
      isYou: json["is_you"] == true,
    );
  }
}

/// Icons returned on guide list items (`spark`, `medal-gold`, …). Null → tick.
enum FanLeaderboardGuideIcon {
  spark,
  medalGold,
  medalSilver,
  medalBronze,
  reward,
  check;

  static FanLeaderboardGuideIcon fromApi(dynamic raw) {
    if (raw == null) return FanLeaderboardGuideIcon.check;
    final key = raw.toString().trim().toLowerCase();
    if (key.isEmpty || key == "null") return FanLeaderboardGuideIcon.check;
    switch (key) {
      case "spark":
      case "star":
        return FanLeaderboardGuideIcon.spark;
      case "medal-gold":
      case "gold":
        return FanLeaderboardGuideIcon.medalGold;
      case "medal-silver":
      case "silver":
        return FanLeaderboardGuideIcon.medalSilver;
      case "medal-bronze":
      case "bronze":
        return FanLeaderboardGuideIcon.medalBronze;
      case "reward":
      case "rewards":
        return FanLeaderboardGuideIcon.reward;
      case "check":
      case "tick":
      case "checkmark":
        return FanLeaderboardGuideIcon.check;
      default:
        return FanLeaderboardGuideIcon.check;
    }
  }
}

class FanLeaderboardGuideItem {
  const FanLeaderboardGuideItem({
    required this.icon,
    required this.heading,
    required this.text,
  });

  final FanLeaderboardGuideIcon icon;
  final String heading;
  final String text;

  factory FanLeaderboardGuideItem.fromJson(Map<String, dynamic> json) {
    return FanLeaderboardGuideItem(
      icon: FanLeaderboardGuideIcon.fromApi(json["icon"]),
      heading: _nullableString(json["heading"]) ?? "",
      text: json["text"]?.toString() ?? "",
    );
  }
}

class FanLeaderboardGuideTab {
  const FanLeaderboardGuideTab({
    required this.key,
    required this.position,
    required this.tabLabel,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.items,
  });

  final String key;
  final int position;
  final String tabLabel;
  final String title;
  final String subtitle;
  final List<String> body;
  final List<FanLeaderboardGuideItem> items;

  factory FanLeaderboardGuideTab.fromJson(Map<String, dynamic> json) {
    final rawBody = json["body"];
    final body = rawBody is List
        ? rawBody.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    final rawItems = json["items"];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (e) => FanLeaderboardGuideItem.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(growable: false)
        : const <FanLeaderboardGuideItem>[];

    return FanLeaderboardGuideTab(
      key: json["key"]?.toString() ?? "",
      position: _asInt(json["position"]),
      tabLabel: json["tab_label"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      subtitle: json["subtitle"]?.toString() ?? "",
      body: body,
      items: items,
    );
  }
}

class FanLeaderboardGuide {
  const FanLeaderboardGuide({
    required this.ctaLabel,
    required this.consentNote,
    required this.tabs,
  });

  final String ctaLabel;
  final String consentNote;
  final List<FanLeaderboardGuideTab> tabs;

  bool get hasContent => tabs.isNotEmpty;

  factory FanLeaderboardGuide.fromJson(Map<String, dynamic> json) {
    final rawTabs = json["tabs"];
    final tabs = rawTabs is List
        ? rawTabs
              .whereType<Map>()
              .map(
                (e) => FanLeaderboardGuideTab.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(growable: false)
        : const <FanLeaderboardGuideTab>[];

    tabs.sort((a, b) => a.position.compareTo(b.position));

    return FanLeaderboardGuide(
      ctaLabel: json["cta_label"]?.toString() ?? "Start engaging",
      consentNote: json["consent_note"]?.toString() ?? "",
      tabs: tabs,
    );
  }
}

class FanLeaderboardData {
  const FanLeaderboardData({
    required this.title,
    required this.subtitle,
    required this.podium,
    this.currentUser,
    required this.participants,
    this.guide,
    this.nextCursor,
    required this.hasMore,
  });

  final String title;
  final String subtitle;
  final List<FanLeaderboardEntry> podium;
  final FanLeaderboardEntry? currentUser;
  final List<FanLeaderboardEntry> participants;
  final FanLeaderboardGuide? guide;
  final String? nextCursor;
  final bool hasMore;

  factory FanLeaderboardData.fromJson(Map<String, dynamic> json) {
    final podium = _entries(json["podium"]);
    final participants = _entries(json["participants"]);

    FanLeaderboardEntry? currentUser;
    final rawCurrent = json["current_user"];
    if (rawCurrent is Map) {
      currentUser = FanLeaderboardEntry.fromJson(
        Map<String, dynamic>.from(rawCurrent),
      );
    }

    FanLeaderboardGuide? guide;
    final rawGuide = json["guide"];
    if (rawGuide is Map) {
      guide = FanLeaderboardGuide.fromJson(Map<String, dynamic>.from(rawGuide));
    }

    final meta = json["meta"];
    String? nextCursor;
    var hasMore = false;
    if (meta is Map) {
      final cursorRaw = meta["next_cursor"];
      if (cursorRaw is String && cursorRaw.isNotEmpty) {
        nextCursor = cursorRaw;
      }
      hasMore = meta["has_more"] == true || nextCursor != null;
    }

    return FanLeaderboardData(
      title: json["title"]?.toString() ?? "Leaderboard",
      subtitle: json["subtitle"]?.toString() ?? "Leaderboard",
      podium: podium,
      currentUser: currentUser,
      participants: participants,
      guide: guide,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }

  static List<FanLeaderboardEntry> _entries(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => FanLeaderboardEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? "") ?? 0;
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
