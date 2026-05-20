/// One row from `application_process.talent_categories`.
class ApplicationTalentCategory {
  const ApplicationTalentCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory ApplicationTalentCategory.fromJson(Map<String, dynamic> json) {
    return ApplicationTalentCategory(
      id: (json["id"] as num).toInt(),
      name: json["name"] as String,
    );
  }
}

/// One row from `application_process.locations`.
class ApplicationProcessLocation {
  const ApplicationProcessLocation({required this.state, required this.lgas});

  final String state;
  final List<String> lgas;

  factory ApplicationProcessLocation.fromJson(Map<String, dynamic> json) {
    final raw = json["lgas"] as List<dynamic>? ?? const [];
    return ApplicationProcessLocation(
      state: json["state"] as String,
      lgas: raw.map((e) => e as String).toList(),
    );
  }
}

/// `gender_options` / `presentation_modes` entry.
class ApplicationLabelValue {
  const ApplicationLabelValue({required this.label, required this.value});

  final String label;
  final String value;

  factory ApplicationLabelValue.fromJson(Map<String, dynamic> json) {
    final label = json["label"] as String? ?? json["name"] as String? ?? "";
    return ApplicationLabelValue(label: label, value: json["value"] as String);
  }
}

/// `data.application_process` from `GET /application/process`.
class ApplicationProcess {
  const ApplicationProcess({
    required this.talentCategories,
    required this.locations,
    required this.banks,
    required this.genderOptions,
    required this.presentationModes,
    required this.nearestCampuses,
    required this.isFinalStep,
    required this.collectBankDetails,
  });

  final List<ApplicationTalentCategory> talentCategories;
  final List<ApplicationProcessLocation> locations;
  final List<String> banks;
  final List<ApplicationLabelValue> genderOptions;
  final List<ApplicationLabelValue> presentationModes;

  /// Options for contact step `nearest_campus` (submit [ApplicationLabelValue.value]).
  final List<ApplicationLabelValue> nearestCampuses;
  final bool isFinalStep;
  final bool collectBankDetails;

  factory ApplicationProcess.fromJson(Map<String, dynamic> json) {
    return ApplicationProcess(
      talentCategories:
          (json["talent_categories"] as List<dynamic>? ?? const [])
              .map(
                (e) => ApplicationTalentCategory.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      locations: (json["locations"] as List<dynamic>? ?? const [])
          .map(
            (e) =>
                ApplicationProcessLocation.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      banks: (json["banks"] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      genderOptions: (json["gender_options"] as List<dynamic>? ?? const [])
          .map((e) => ApplicationLabelValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      presentationModes:
          (json["presentation_modes"] as List<dynamic>? ?? const [])
              .map(
                (e) =>
                    ApplicationLabelValue.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      nearestCampuses: (json["nearest_campuses"] as List<dynamic>? ?? const [])
          .map((e) => ApplicationLabelValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      isFinalStep: json["is_final_step"] as bool? ?? false,
      collectBankDetails: _boolField(json["collect_bank_details"]),
    );
  }

  static bool _boolField(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final s = value.toLowerCase();
      return s == "true" || s == "1" || s == "yes";
    }
    return false;
  }

  ApplicationProcessLocation? locationForState(String state) {
    final trimmedState = state.trim();
    for (final location in locations) {
      if (location.state == trimmedState) {
        return location;
      }
    }
    return null;
  }

  /// Human-readable campus name for [stored] (API `value`); falls back to [stored].
  String nearestCampusDisplay(String stored) {
    final v = stored.trim();
    if (v.isEmpty) return v;
    for (final c in nearestCampuses) {
      if (c.value == v) return c.label;
    }
    return stored;
  }

  /// Resolves [ApplicationDraft.talentCategory] (category name) to an API id.
  int resolveTalentCategoryId(String categoryName) {
    final trimmedCategoryName = categoryName.trim();
    for (final category in talentCategories) {
      if (category.name.trim() == trimmedCategoryName) {
        return category.id;
      }
    }
    if (talentCategories.isNotEmpty) {
      return talentCategories.first.id;
    }
    return 1;
  }
}
