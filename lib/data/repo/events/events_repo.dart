import "package:dth_v4/data/models/model.dart";

abstract class EventsRepo {
  /// First page: omit [cursor]. Subsequent pages: pass [nextCursor] from the prior result.
  Future<PaginatedResult<EventListItem>> fetchUpcomingEvents({
    String? cursor,
    int perPage = 15,
  });

  Future<PaginatedResult<EventListItem>> fetchBookedEvents({
    String? cursor,
    int perPage = 15,
  });

  Future<EventDetail> fetchEvent(String eventUid);
}
