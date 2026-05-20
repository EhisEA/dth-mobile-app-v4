import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Tickets tab: first page of upcoming (horizontal strip) + paginated booked list.
class TicketHomeViewModel extends BaseChangeNotifierViewModel {
  TicketHomeViewModel(this._eventsRepo);

  final EventsRepo _eventsRepo;

  ViewModelState _upcomingState = const ViewModelState.busy();
  ViewModelState get upcomingState => _upcomingState;

  ViewModelState _bookedState = const ViewModelState.busy();
  ViewModelState get bookedState => _bookedState;

  List<EventListItem> _upcomingPreview = const [];
  List<EventListItem> get upcomingPreview => _upcomingPreview;

  List<EventListItem> _bookedEvents = const [];
  List<EventListItem> get bookedEvents => _bookedEvents;

  String? _bookedNextCursor;
  bool get hasMoreBooked => _bookedNextCursor != null;

  bool _bookedLoadingMore = false;
  bool get bookedLoadingMore => _bookedLoadingMore;

  Future<void> loadInitial() async {
    _upcomingState = const ViewModelState.busy();
    _bookedState = const ViewModelState.busy();
    notifyListeners();
    await Future.wait<void>([
      _loadUpcoming(),
      _loadBooked(),
    ]);
  }

  /// Pull-to-refresh: reload upcoming and booked without the initial full-screen busy state.
  Future<void> refresh() async {
    await Future.wait<void>([
      _loadUpcoming(),
      _loadBooked(),
    ]);
  }

  Future<void> retryUpcoming() async {
    _upcomingState = const ViewModelState.busy();
    notifyListeners();
    await _loadUpcoming();
  }

  Future<void> retryBooked() async {
    _bookedState = const ViewModelState.busy();
    notifyListeners();
    await _loadBooked();
  }

  Future<void> _loadUpcoming() async {
    try {
      final upcoming = await _eventsRepo.fetchUpcomingEvents(perPage: 16);
      _upcomingPreview = upcoming.items;
      _upcomingState = const ViewModelState.idle();
    } on ApiFailure catch (e) {
      _upcomingState = ViewModelState.error(e);
    }
    notifyListeners();
  }

  Future<void> _loadBooked() async {
    try {
      final booked = await _eventsRepo.fetchBookedEvents(perPage: 16);
      _bookedEvents = booked.items;
      _bookedNextCursor = booked.nextCursor;
      _bookedState = const ViewModelState.idle();
    } on ApiFailure catch (e) {
      _bookedState = ViewModelState.error(e);
    }
    notifyListeners();
  }

  Future<void> loadMoreBooked() async {
    final cursor = _bookedNextCursor;
    if (cursor == null || _bookedLoadingMore) return;
    _bookedLoadingMore = true;
    notifyListeners();
    try {
      final page = await _eventsRepo.fetchBookedEvents(
        cursor: cursor,
        perPage: 16,
      );
      _bookedEvents = [..._bookedEvents, ...page.items];
      _bookedNextCursor = page.nextCursor;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(title: "Tickets", message: e.message);
    } finally {
      _bookedLoadingMore = false;
      notifyListeners();
    }
  }
}

final ticketHomeViewModelProvider = ChangeNotifierProvider<TicketHomeViewModel>(
  (ref) {
    return TicketHomeViewModel(ref.read(eventsRepositoryProvider));
  },
);
