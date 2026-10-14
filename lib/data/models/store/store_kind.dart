import "package:flutter/foundation.dart";

enum StoreKind {
  merch,
  liveEvent;

  /// Path segment for `GET /api/stores/{store}`.
  String get apiStoreId => this == StoreKind.merch ? "merch" : "event";
}

@immutable
class StoreCategory {
  const StoreCategory({required this.id, required this.label});

  /// Local synthetic chip — not returned by the API.
  static const String allId = "all";

  final String id;
  final String label;
}

/// Short labels for common size names (API may send "Small"/"Medium"/"Large").
String storeSizeDisplayLabel(String size) {
  switch (size.trim().toLowerCase()) {
    case "small":
    case "s":
      return "S";
    case "medium":
    case "m":
      return "M";
    case "large":
    case "l":
      return "L";
    default:
      return size.trim();
  }
}
