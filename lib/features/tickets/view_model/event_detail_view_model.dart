import "dart:async";

import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class EventDetailViewModel extends BaseChangeNotifierViewModel {
  EventDetailViewModel(this.eventUid, this._eventsRepo) {
    unawaited(_load());
  }

  final String eventUid;
  final EventsRepo _eventsRepo;

  EventDetail? _event;
  EventDetail? get event => _event;

  Future<void> _load() async {
    try {
      changeBaseState(const ViewModelState.busy());
      _event = await _eventsRepo.fetchEvent(eventUid);
      changeBaseState(const ViewModelState.idle());
      notifyListeners();
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
    }
  }

  Future<void> refresh() async {
    try {
      changeBaseState(const ViewModelState.busy());
      _event = await _eventsRepo.fetchEvent(eventUid);
      changeBaseState(const ViewModelState.idle());
      notifyListeners();
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(title: "Event", message: e.message);
    }
  }
}

final eventDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<EventDetailViewModel, String>((ref, eventUid) {
      return EventDetailViewModel(
        eventUid,
        ref.read(eventsRepositoryProvider),
      );
    });
