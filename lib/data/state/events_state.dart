import "package:dth_v4/data/models/event_list_item.dart";
import "package:dth_v4/data/models/paginated_result.dart";
import "package:dth_v4/data/repo/events/events_repo.dart";
import "package:dth_v4/data/repo/events/events_repo_impl.dart";
import "package:dth_v4/data/state/base_state.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Shared cache and network access for events lists (tickets tab).
class EventsState extends BaseState {
  EventsState(this._repo);

  final EventsRepo _repo;

  List<EventListItem> upcomingEvents = const [];
  final ValueNotifier<List<EventListItem>> bookedEvents =
      ValueNotifier(const []);
  String? bookedNextCursor;

  Future<List<EventListItem>> fetchUpcomingEvents({int perPage = 15}) async {
    final page = await _repo.fetchUpcomingEvents(perPage: perPage);
    upcomingEvents = page.items;
    return page.items;
  }

  Future<PaginatedResult<EventListItem>> fetchBookedEvents({
    String? cursor,
    int perPage = 16,
    bool append = false,
  }) async {
    final page = await _repo.fetchBookedEvents(
      cursor: cursor,
      perPage: perPage,
    );
    bookedEvents.value = append
        ? [...bookedEvents.value, ...page.items]
        : page.items;
    bookedNextCursor = page.nextCursor;
    return page;
  }

  Future<PaginatedResult<EventListItem>> fetchMoreBookedEvents({
    int perPage = 16,
  }) async {
    final cursor = bookedNextCursor;
    if (cursor == null) {
      return const PaginatedResult(items: [], nextCursor: null);
    }
    return fetchBookedEvents(cursor: cursor, perPage: perPage, append: true);
  }

  @override
  void dispose() {
    bookedEvents.dispose();
  }
}

final eventsStateProvider = Provider<EventsState>((ref) {
  final state = EventsState(ref.read(eventsRepositoryProvider));
  ref.onDispose(state.dispose);
  return state;
});
