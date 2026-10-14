class DthCountry {
  const DthCountry({
    required this.dialCode,
    required this.isoCode,
    required this.flagDataUri,
    this.name = "",
    this.states = const [],
  });

  final String dialCode;
  final String isoCode;

  /// API returns `data:image/png;base64,...`
  final String flagDataUri;

  /// Display name from `/api/countries` (e.g. "Nigeria").
  final String name;

  /// Fixed state names for address forms. Empty → free-text state.
  final List<String> states;

  bool get hasFixedStates => states.isNotEmpty;

  factory DthCountry.fromJson(Map<String, dynamic> json) {
    final statesRaw = json["states"];
    final states = statesRaw is List
        ? statesRaw
              .whereType<Map>()
              .map((e) => (e["name"] ?? "").toString().trim())
              .where((s) => s.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return DthCountry(
      dialCode: _stringField(json["dial_code"]),
      isoCode: _stringField(json["iso_code"]).toUpperCase(),
      flagDataUri: _stringField(json["flag"]),
      name: _stringField(json["name"]),
      states: states,
    );
  }

  Map<String, dynamic> toJson() => {
    "dial_code": dialCode,
    "iso_code": isoCode,
    "flag": flagDataUri,
    "name": name,
    "states": [for (final s in states) {"name": s}],
  };

  static String _stringField(Object? value) {
    if (value == null) return "";
    if (value is String) return value;
    return value.toString();
  }

  /// Resolves flag (and dial code) from the cached `/countries` list using only
  /// [isoCode] from the backend (case-insensitive). Returns null if not found.
  static DthCountry? findByIso(Iterable<DthCountry> countries, String isoCode) {
    final u = isoCode.trim().toUpperCase();
    if (u.isEmpty) return null;
    for (final c in countries) {
      if (c.isoCode == u) return c;
    }
    return null;
  }

  static DthCountry? findByName(Iterable<DthCountry> countries, String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return null;
    for (final c in countries) {
      if (c.name.trim().toLowerCase() == n) return c;
    }
    return null;
  }
}
