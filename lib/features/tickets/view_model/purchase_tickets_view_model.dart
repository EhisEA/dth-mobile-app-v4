import "package:dth_v4/core/extension/double_extension.dart";
import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/subscription/views/confirmation_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class PurchaseTicketsViewModel extends BaseChangeNotifierViewModel {
  PurchaseTicketsViewModel(this.eventUid, this._ticketsRepo) {
    _load();
  }

  final String eventUid;
  final TicketsRepo _ticketsRepo;

  Future<void> Function()? _onPurchaseSuccess;

  void bindOnPurchaseSuccess(Future<void> Function()? callback) {
    _onPurchaseSuccess = callback;
  }

  List<AvailableTicket> _tickets = const [];
  List<AvailableTicket> get tickets => _tickets;

  final Map<String, int> _quantities = {};

  int quantityFor(String ticketUid) => _quantities[ticketUid] ?? 0;

  bool get hasSelection => _quantities.values.any((quantity) => quantity > 0);

  double get totalAmount {
    var total = 0.0;
    for (final ticket in _tickets) {
      final qty = quantityFor(ticket.uid);
      if (qty > 0) {
        total += ticket.amountValue * qty;
      }
    }
    return total;
  }

  String get formattedTotal => "₦${totalAmount.toMoneyWholeNumber()}";

  Future<void> _load() async {
    try {
      changeBaseState(const ViewModelState.busy());
      _tickets = await _ticketsRepo.fetchAvailableTickets(eventUid);
      _quantities.clear();
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
    }
  }

  Future<void> refresh() async {
    try {
      changeBaseState(const ViewModelState.busy());
      _tickets = await _ticketsRepo.fetchAvailableTickets(eventUid);
      _pruneQuantities();
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(title: "Tickets", message: e.message);
    }
  }

  void increment(String ticketUid) {
    final ticket = _ticketByUid(ticketUid);
    if (ticket == null) return;

    final current = quantityFor(ticketUid);
    if (ticket.availableTickets > 0 && current >= ticket.availableTickets) {
      return;
    }

    _quantities[ticketUid] = current + 1;
    notifyListeners();
  }

  void decrement(String ticketUid) {
    final current = quantityFor(ticketUid);
    if (current <= 0) return;
    if (current == 1) {
      _quantities.remove(ticketUid);
    } else {
      _quantities[ticketUid] = current - 1;
    }
    notifyListeners();
  }

  void setQuantity(String ticketUid, int quantity) {
    final ticket = _ticketByUid(ticketUid);
    if (ticket == null) return;

    var next = quantity < 0 ? 0 : quantity;
    if (ticket.availableTickets > 0 && next > ticket.availableTickets) {
      next = ticket.availableTickets;
    }

    if (next <= 0) {
      _quantities.remove(ticketUid);
    } else {
      _quantities[ticketUid] = next;
    }
    notifyListeners();
  }

  void _pruneQuantities() {
    final validUids = _tickets.map((t) => t.uid).toSet();
    _quantities.removeWhere((uid, _) => !validUids.contains(uid));
    for (final ticket in _tickets) {
      final qty = quantityFor(ticket.uid);
      if (ticket.availableTickets > 0 && qty > ticket.availableTickets) {
        _quantities[ticket.uid] = ticket.availableTickets;
      }
    }
  }

  AvailableTicket? _ticketByUid(String ticketUid) {
    for (final ticket in _tickets) {
      if (ticket.uid == ticketUid) return ticket;
    }
    return null;
  }

  List<TicketPurchaseLine> get _selectedLines {
    return _tickets
        .map((ticket) {
          final qty = quantityFor(ticket.uid);
          if (qty <= 0) return null;
          return TicketPurchaseLine(
            seatTypeUid: ticket.uid,
            quantity: qty,
            amount: ticket.amountValue * qty,
          );
        })
        .whereType<TicketPurchaseLine>()
        .toList();
  }

  Future<void> checkout() async {
    final lines = _selectedLines;
    if (lines.isEmpty) return;

    try {
      setState(_checkoutKey, const ViewModelState.busy());
      final response = await _ticketsRepo.purchaseTickets(
        eventUid: eventUid,
        lines: lines,
      );
      final data = response.data;
      if (data == null ||
          data.authorizationUrl.isEmpty ||
          data.reference.isEmpty) {
        setState(_checkoutKey, const ViewModelState.idle());
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

      final paymentSucceeded = returnedFromCallback == true;
      if (paymentSucceeded) {
        await _ticketsRepo.verifyPayment(reference: data.reference);
        DthFlushBar.instance.showSuccess(
          title: "Tickets",
          message: "Your payment was confirmed.",
        );
        _tickets = await _ticketsRepo.fetchAvailableTickets(eventUid);
        _quantities.clear();
        notifyListeners();
      }

      await MobileNavigationService.instance.push(
        ConfirmationView.path,
        extra: {
          RoutingArgumentKey.confirmationSuccess: paymentSucceeded,
          RoutingArgumentKey.confirmationFlow: ConfirmationFlow.ticket,
          RoutingArgumentKey.confirmationEventUid: eventUid,
          if (paymentSucceeded)
            RoutingArgumentKey.confirmationOnSuccess: _onPurchaseSuccess,
          RoutingArgumentKey.confirmationSuccessDescription:
              "Your payment was successful. Your tickets are ready — view them on the event page.",
          RoutingArgumentKey.confirmationFailureDescription:
              "We couldn't process your payment. Please try again or use a different method.",
        },
      );

      setState(_checkoutKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      setState(_checkoutKey, ViewModelState.error(e));
      DthFlushBar.instance.showError(title: "Error", message: e.message);
    }
  }

  static final _checkoutKey = "checkoutKey";
  ViewModelState get checkoutState =>
      getState(_checkoutKey) ?? const ViewModelState.idle();
}

final purchaseTicketsViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<PurchaseTicketsViewModel, String>((ref, eventUid) {
      return PurchaseTicketsViewModel(
        eventUid,
        ref.read(ticketsRepositoryProvider),
      );
    });
