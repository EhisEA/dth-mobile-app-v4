import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class TimelineRepoImpl implements TimelineRepo {
  TimelineRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<PaginatedResult<TimelinePost>> fetchTimeline({String? cursor}) async {
    final response = await _networkService.get(
      ApiRoute.timeline,
      queryParams: _cursorParams(cursor),
    );
    return _parsePaginated(
      response.data,
      listKey: "posts",
      fromJson: TimelinePost.fromJson,
    );
  }

  @override
  Future<PaginatedResult<TimelineReel>> fetchTimelineReels({
    String? cursor,
  }) async {
    final response = await _networkService.get(
      ApiRoute.timelineReels,
      queryParams: _cursorParams(cursor),
    );
    return _parsePaginated(
      response.data,
      listKey: "reels",
      fromJson: TimelineReel.fromJson,
    );
  }

  Map<String, dynamic>? _cursorParams(String? cursor) {
    if (cursor == null || cursor.isEmpty) return null;
    return {"cursor": cursor};
  }

  /// Parses the cursor-paginated envelope:
  /// `{ data: { <listKey>: { data: [...], next_cursor: "...", ... } } }`
  PaginatedResult<T> _parsePaginated<T>(
    dynamic root, {
    required String listKey,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final empty = PaginatedResult<T>(items: const [], nextCursor: null);
    if (root is! Map<String, dynamic>) return empty;
    final data = root["data"];
    if (data is! Map<String, dynamic>) return empty;
    final outer = data[listKey];
    if (outer is! Map<String, dynamic>) return empty;
    final list = outer["data"];
    if (list is! List<dynamic>) return empty;

    final cursorRaw = outer["next_cursor"];
    final nextCursor = cursorRaw is String && cursorRaw.isNotEmpty
        ? cursorRaw
        : null;

    final items = list
        .map((e) {
          if (e is! Map) return null;
          return fromJson(Map<String, dynamic>.from(e));
        })
        .whereType<T>()
        .toList();

    return PaginatedResult<T>(items: items, nextCursor: nextCursor);
  }
}

final timelineRepositoryProvider = Provider<TimelineRepo>((ref) {
  return TimelineRepoImpl(networkService: ref.read(networkServiceProvider));
});
