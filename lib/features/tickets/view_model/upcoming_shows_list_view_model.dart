import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Full upcoming list with infinite scroll (used in [UpcomingShowsView]).
class UpcomingShowsListViewModel extends BaseChangeNotifierViewModel {
  UpcomingShowsListViewModel(this._eventsRepo);

  final EventsRepo _eventsRepo;

  List<EventListItem> _items = const [];
  List<EventListItem> get items => _items;

  String? _nextCursor;
  bool get hasMore => _nextCursor != null;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  Future<void> loadFirstPage() async {
    try {
      changeBaseState(const ViewModelState.busy());
      final page = await _eventsRepo.fetchUpcomingEvents(perPage: 16);
      _items = page.items;
      _nextCursor = page.nextCursor;
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
    }
  }

  Future<void> refresh() async {
    try {
      final page = await _eventsRepo.fetchUpcomingEvents(perPage: 16);
      _items = page.items;
      _nextCursor = page.nextCursor;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(title: "Upcoming", message: e.message);
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _eventsRepo.fetchUpcomingEvents(
        cursor: cursor,
        perPage: 16,
      );
      _items = [..._items, ...page.items];
      _nextCursor = page.nextCursor;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(title: "Upcoming", message: e.message);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }
}

final upcomingShowsListViewModelProvider =
    ChangeNotifierProvider<UpcomingShowsListViewModel>((ref) {
      return UpcomingShowsListViewModel(ref.read(eventsRepositoryProvider));
    });
