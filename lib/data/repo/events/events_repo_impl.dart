import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class EventsRepoImpl implements EventsRepo {
  EventsRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<PaginatedResult<EventListItem>> fetchUpcomingEvents({
    String? cursor,
    int perPage = 16,
  }) async {
    final response = await _networkService.get(
      ApiRoute.eventsUpcoming,
      queryParams: _pageParams(cursor: cursor, perPage: perPage),
    );
    return _parsePaginated(
      response.data,
      listKey: "upcoming_events",
      fromJson: EventListItem.fromJson,
    );
  }

  @override
  Future<PaginatedResult<EventListItem>> fetchBookedEvents({
    String? cursor,
    int perPage = 16,
  }) async {
    final response = await _networkService.get(
      ApiRoute.eventsBooked,
      queryParams: _pageParams(cursor: cursor, perPage: perPage),
    );
    return _parsePaginated(
      response.data,
      listKey: "booked_events",
      fromJson: EventListItem.fromJson,
    );
  }

  @override
  Future<EventDetail> fetchEvent(String eventUid) async {
    final response = await _networkService.get(ApiRoute.event(eventUid));
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response shape");
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Missing data block");
    }
    final event = data["event"];
    if (event is! Map<String, dynamic>) {
      throw ApiFailure("Event not found");
    }
    return EventDetail.fromJson(event);
  }

  Map<String, dynamic> _pageParams({String? cursor, required int perPage}) {
    final params = <String, dynamic>{"per_page": perPage.toString()};
    if (cursor != null && cursor.isNotEmpty) {
      params["cursor"] = cursor;
    }
    return params;
  }

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

final eventsRepositoryProvider = Provider<EventsRepo>((ref) {
  return EventsRepoImpl(networkService: ref.read(networkServiceProvider));
});
