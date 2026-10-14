import "dart:convert";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/dth_country.dart";
import "package:dth_v4/data/repo/countries/countries.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

bool _isUsableCountriesCache(List<DthCountry> list) {
  if (list.isEmpty) return false;
  // Older cache entries omitted `name` / `states`; treat those as a miss.
  return list.every((c) => c.name.trim().isNotEmpty);
}

List<DthCountry>? _tryReadCountriesCache(dynamic raw) {
  try {
    final List<dynamic> decoded;
    if (raw is String && raw.isNotEmpty) {
      decoded = jsonDecode(raw) as List<dynamic>;
    } else if (raw is List<dynamic>) {
      decoded = raw;
    } else {
      return null;
    }
    final list = decoded
        .whereType<Map>()
        .map((e) => DthCountry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (_isUsableCountriesCache(list)) return list;
  } on Object {
    // fall through to network
  }
  return null;
}

/// Loads countries once per app session; prefers disk cache to avoid repeat HTTP.
final countriesListProvider = FutureProvider<List<DthCountry>>((ref) async {
  final cache = ref.read(localCacheProvider);
  final cached = _tryReadCountriesCache(
    cache.getFromLocalCache(CacheKeys.countries),
  );
  if (cached != null) return cached;

  final repo = ref.read(countriesRepositoryProvider);
  final list = await repo.fetchCountries();
  if (list.isNotEmpty) {
    await cache.saveToLocalCache(
      key: CacheKeys.countries,
      value: list.map((c) => c.toJson()).toList(),
    );
  }
  return list;
});
