import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Tickets tab: [EventsState] holds cached lists; this VM owns loading/error UI state.
class TicketHomeViewModel extends BaseChangeNotifierViewModel {
  TicketHomeViewModel(this._eventsState);

  final EventsState _eventsState;

  static const _upcomingKey = "ticketHomeUpcoming";
  static const _bookedKey = "ticketHomeBooked";

  ViewModelState get upcomingState =>
      getState(_upcomingKey) ?? const ViewModelState.busy();

  ViewModelState get bookedState =>
      getState(_bookedKey) ?? const ViewModelState.busy();

  List<EventListItem> get upcomingPreview => _eventsState.upcomingEvents;

  ValueNotifier<List<EventListItem>> get bookedEvents =>
      _eventsState.bookedEvents;

  bool get hasMoreBooked => _eventsState.bookedNextCursor != null;

  bool _bookedLoadingMore = false;
  bool get bookedLoadingMore => _bookedLoadingMore;

  // Future<void> loadInitial() async {
  //   await Future.wait<void>([_loadUpcoming(), _loadBooked()]);
  // }

  Future<void> refresh() async {
    await Future.wait<void>([_loadUpcoming(), _loadBooked()]);
  }

  Future<void> retryUpcoming() async {
    await _loadUpcoming();
  }

  Future<void> retryBooked() async {
    await _loadBooked();
  }

  Future<void> loadMoreBooked() async {
    if (_bookedLoadingMore || _eventsState.bookedNextCursor == null) return;
    _bookedLoadingMore = true;
    notifyListeners();
    try {
      await _eventsState.fetchMoreBookedEvents();
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(title: "Tickets", message: e.message);
    } finally {
      _bookedLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _loadUpcoming({bool setBusy = true}) async {
    if (setBusy) {
      setState(_upcomingKey, const ViewModelState.busy());
    }
    try {
      await _eventsState.fetchUpcomingEvents();
      setState(_upcomingKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      setState(_upcomingKey, ViewModelState.error(e));
    }
  }

  Future<void> _loadBooked({bool setBusy = true}) async {
    if (setBusy) {
      setState(_bookedKey, const ViewModelState.busy());
    }
    try {
      await _eventsState.fetchBookedEvents();
      setState(_bookedKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      setState(_bookedKey, ViewModelState.error(e));
    }
  }
}

final ticketHomeViewModelProvider = ChangeNotifierProvider<TicketHomeViewModel>(
  (ref) {
    return TicketHomeViewModel(ref.read(eventsStateProvider));
  },
);
