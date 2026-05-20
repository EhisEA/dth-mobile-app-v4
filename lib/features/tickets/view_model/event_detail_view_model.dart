import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/subscription/views/confirmation_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class EventDetailViewModel extends BaseChangeNotifierViewModel {
  EventDetailViewModel(this.eventUid, this._eventsRepo, this._ticketsRepo) {
    _load();
  }

  final String eventUid;
  final EventsRepo _eventsRepo;
  final TicketsRepo _ticketsRepo;

  EventDetail? _event;
  EventDetail? get event => _event;

  Future<void> _load() async {
    try {
      changeBaseState(const ViewModelState.busy());
      _event = await _eventsRepo.fetchEvent(eventUid);
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
    }
  }

  Future<void> refresh() async {
    try {
      changeBaseState(const ViewModelState.busy());
      _event = await _eventsRepo.fetchEvent(eventUid);
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(title: "Event", message: e.message);
    }
  }

  /// Uses the first configured seat type when the API does not require a picker yet.
  Future<void> purchaseTicket({int quantity = 1}) async {
    final detail = _event;
    if (detail == null) return;

    final seatUid = detail.seatTypes.isNotEmpty ? detail.seatTypes.first.uid : "";
    if (seatUid.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Tickets",
        message: "No seat types are available for this event yet.",
      );
      return;
    }

    try {
      changeBaseState(const ViewModelState.busy());
      final response = await _ticketsRepo.purchaseTickets(
        eventUid: detail.uid,
        seatTypeUid: seatUid,
        quantity: quantity,
      );
      final data = response.data;
      if (data == null ||
          data.authorizationUrl.isEmpty ||
          data.reference.isEmpty) {
        changeBaseState(const ViewModelState.idle());
        DthFlushBar.instance.showError(
          title: "Error",
          message: "Could not start checkout. Please try again.",
        );
        return;
      }

      final returnedFromCallback = await MobileNavigationService.instance
          .navigateTo(
            AppWebView.path,
            extra: {
              RoutingArgumentKey.title: "Buy tickets",
              RoutingArgumentKey.initialURl: data.authorizationUrl,
              RoutingArgumentKey.callbackUrl: data.callbackUrl,
            },
          );

      if (returnedFromCallback == true) {
        await _ticketsRepo.verifyPayment(reference: data.reference);
        DthFlushBar.instance.showSuccess(
          title: "Tickets",
          message: "Your payment was confirmed.",
        );
        _event = await _eventsRepo.fetchEvent(eventUid);
        notifyListeners();
        await MobileNavigationService.instance.push(
          ConfirmationView.path,
          extra: {RoutingArgumentKey.confirmationSuccess: true},
        );
      } else {
        await MobileNavigationService.instance.push(
          ConfirmationView.path,
          extra: {RoutingArgumentKey.confirmationSuccess: false},
        );
      }

      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(title: "Error", message: e.message);
    }
  }
}

final eventDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<EventDetailViewModel, String>((ref, eventUid) {
      return EventDetailViewModel(
        eventUid,
        ref.read(eventsRepositoryProvider),
        ref.read(ticketsRepositoryProvider),
      );
    });
