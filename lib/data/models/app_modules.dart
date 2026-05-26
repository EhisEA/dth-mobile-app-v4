class AppModulesModel {
  const AppModulesModel({
    required this.application,
    required this.livestream,
    required this.timeline,
    required this.ticket,
    required this.voting,
    required this.poll,
    required this.judges,
    required this.subscription,
    required this.reel,
    required this.googleLoginEnabled,
    required this.navigation,
  });

  final bool application;
  final bool livestream;
  final bool timeline;
  final bool ticket;
  final bool voting;
  final bool poll;
  final bool judges;
  final bool subscription;
  final bool reel;

  /// Server-side kill switch for the "Sign in with Google" button. Lets us
  /// hide the OAuth path without shipping a new build (e.g. while Apple
  /// review is pending or the provider is down).
  final bool googleLoginEnabled;

  // Ordered list of tabs to render in the bottom nav. Driving this from
  // the server means we can ship/hide tabs without releasing a new build.
  final List<AppModuleNavItem> navigation;

  factory AppModulesModel.fromJson(Map<String, dynamic> json) {
    final navRaw = json["navigation"];
    final nav = navRaw is List<dynamic>
        ? navRaw
              .whereType<Map>()
              .map(
                (e) => AppModuleNavItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <AppModuleNavItem>[];

    return AppModulesModel(
      application: json["application"] == true,
      livestream: json["livestream"] == true,
      timeline: json["timeline"] == true,
      ticket: json["ticket"] == true,
      voting: json["voting"] == true,
      poll: json["poll"] == true,
      judges: json["judges"] == true,
      subscription: json["subscription"] == true,
      reel: json["reel"] != false,
      googleLoginEnabled: json["google_login_enabled"] == true,
      navigation: nav,
    );
  }

  Map<String, dynamic> toJson() => {
    "application": application,
    "livestream": livestream,
    "timeline": timeline,
    "ticket": ticket,
    "voting": voting,
    "poll": poll,
    "judges": judges,
    "subscription": subscription,
    "reel": reel,
    "google_login_enabled": googleLoginEnabled,
    "navigation": navigation.map((n) => n.toJson()).toList(),
  };
}

class AppModuleNavItem {
  const AppModuleNavItem({required this.name, required this.label});

  /// Stable identifier (e.g. "timeline", "search", "tickets"). Use this for
  /// routing/iconography decisions, not [label] which is display text.
  final String name;
  final String label;

  factory AppModuleNavItem.fromJson(Map<String, dynamic> json) {
    return AppModuleNavItem(
      name: (json["name"] ?? "").toString(),
      label: (json["label"] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() => {"name": name, "label": label};
}
