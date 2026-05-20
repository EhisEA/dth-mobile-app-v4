import "package:flutter/foundation.dart";

/// Result of a cursor-paginated list endpoint.
///
/// Backend envelope (May 2026):
/// ```
/// data: {
///   <key>: { data: [...], next_cursor: "...", per_page: 10, ... }
/// }
/// ```
///
/// `nextCursor == null` means there are no more pages.
@immutable
class PaginatedResult<T> {
  const PaginatedResult({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
