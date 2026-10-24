import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/store/views/store_payment_result_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreCheckoutViewModel extends BaseChangeNotifierViewModel {
  StoreCheckoutViewModel(
    this._repo, {
    Future<void> Function()? onOrderPaid,
    Future<void> Function()? onCartRestored,
  }) : _onOrderPaid = onOrderPaid,
       _onCartRestored = onCartRestored;

  final StoreRepo _repo;
  final Future<void> Function()? _onOrderPaid;
  final Future<void> Function()? _onCartRestored;
  final _log = const AppLogger(StoreCheckoutViewModel);

  StoreKind? _kind;
  StoreCheckoutQuote? _quote;
  String? _promoCode;
  String? _addressUid;
  int _requestId = 0;
  bool _placing = false;

  /// A Paystack order whose payment could not be confirmed either way. While
  /// set, Pay settles this order instead of starting a second checkout.
  _PendingPayment? _pending;

  /// Waits between verify attempts after the Paystack callback.
  static const _verifyRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  StoreKind? get kind => _kind;
  StoreCheckoutQuote? get quote => _quote;
  String? get promoCode => _promoCode;
  String? get addressUid => _addressUid;

  bool get isQuoteBusy => isBaseBusy && !_placing;
  bool get isPlacingOrder => _placing;
  bool get canCheckout => _quote?.canCheckout == true;
  bool get requiresAddress => _quote?.requiresAddress == true;

  /// Prepare [kind], optional address, and fetch the initial quote.
  /// Returns `true` when a quote was loaded successfully.
  Future<bool> load(StoreKind kind, {String? addressUid}) async {
    // Keep an unresolved payment across reloads so it is settled before the
    // next charge. Logout clears it through [reset].
    final pending = _pending;
    reset();
    _pending = pending;
    _kind = kind;
    if (addressUid != null) setAddressUid(addressUid);
    return fetchQuote();
  }

  Future<bool> fetchQuote({bool showError = true}) async {
    final kind = _kind;
    if (kind == null) return false;

    final requestId = ++_requestId;
    changeBaseState(const ViewModelState.busy());
    try {
      final result = await _repo.quoteCheckout(
        kind.apiStoreId,
        promoCode: _promoCode,
        addressUid: _addressUid,
      );
      if (requestId != _requestId) return false;
      _quote = result;
      final quotedUid = result.address?.uid.trim();
      if (quotedUid != null && quotedUid.isNotEmpty) {
        _addressUid = quotedUid;
      }
      changeBaseState(const ViewModelState.idle());
      return true;
    } on ApiFailure catch (e, s) {
      if (requestId != _requestId) return false;
      _log.e("[quote] ApiFailure: ${e.message}", error: e, stackTrace: s);
      _quote = null;
      changeBaseState(ViewModelState.error(e));
      if (showError) {
        DthFlushBar.instance.showError(title: "Checkout", message: e.message);
      }
      return false;
    } catch (e, s) {
      if (requestId != _requestId) return false;
      _log.e("[quote] unexpected", error: e, stackTrace: s);
      _quote = null;
      final failure = ApiFailure(e.toString());
      changeBaseState(ViewModelState.error(failure));
      if (showError) {
        DthFlushBar.instance.showError(
          title: "Checkout",
          message: "Could not load checkout. Please try again.",
        );
      }
      return false;
    }
  }

  /// Quote with [code] and keep it only if the server applies it. On
  /// rejection or error the current promo and quote stay as they were.
  Future<void> applyPromo(String code) async {
    final kind = _kind;
    if (kind == null) return;
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      _promoCode = null;
      await fetchQuote();
      return;
    }

    final requestId = ++_requestId;
    changeBaseState(const ViewModelState.busy());
    try {
      final result = await _repo.quoteCheckout(
        kind.apiStoreId,
        promoCode: trimmed,
        addressUid: _addressUid,
      );
      if (requestId != _requestId) return;
      final promo = result.promo;
      final message = promo?.message?.trim() ?? "";
      if (promo == null || !promo.applied) {
        changeBaseState(const ViewModelState.idle());
        DthFlushBar.instance.showError(
          title: "Promo",
          message: message.isNotEmpty
              ? message
              : "This promo code can't be applied.",
        );
        return;
      }
      _promoCode = trimmed;
      _quote = result;
      final quotedUid = result.address?.uid.trim();
      if (quotedUid != null && quotedUid.isNotEmpty) {
        _addressUid = quotedUid;
      }
      changeBaseState(const ViewModelState.idle());
      DthFlushBar.instance.showSuccess(
        title: "Promo",
        message: message.isNotEmpty ? message : "Promo code applied.",
      );
    } on ApiFailure catch (e, s) {
      if (requestId != _requestId) return;
      _log.e("[promo] ApiFailure: ${e.message}", error: e, stackTrace: s);
      changeBaseState(const ViewModelState.idle());
      DthFlushBar.instance.showError(title: "Promo", message: e.message);
    } catch (e, s) {
      if (requestId != _requestId) return;
      _log.e("[promo] unexpected", error: e, stackTrace: s);
      changeBaseState(const ViewModelState.idle());
      DthFlushBar.instance.showError(
        title: "Promo",
        message: "Could not apply promo. Please try again.",
      );
    }
  }

  /// Keep [uid] for the next quote / checkout (Merch Store delivery address).
  void setAddressUid(String? uid) {
    final next = uid?.trim();
    _addressUid = (next == null || next.isEmpty) ? null : next;
  }

  /// Call after the shipping address screen closes.
  Future<void> onAddressChanged({String? addressUid}) async {
    setAddressUid(addressUid);
    await fetchQuote();
  }

  /// Create the order, open Paystack when needed, verify, then result screen.
  Future<void> placeOrder() async {
    final kind = _kind;
    if (kind == null || _placing) return;
    final pending = _pending;
    if (pending == null && !canCheckout) return;

    _placing = true;
    notifyListeners();
    try {
      if (pending != null) {
        // An earlier payment is unresolved. Settle it before charging again.
        final confirmed = await _verifyWithRetry(pending.reference);
        await _settle(pending, confirmed: confirmed);
        return;
      }

      final result = await _repo.checkout(
        kind.apiStoreId,
        promoCode: _promoCode,
        addressUid: _addressUid,
      );

      if (!result.requiresPayment) {
        await _showPaid();
        return;
      }

      final authUrl = result.authorizationUrl?.trim() ?? "";
      final reference = result.reference?.trim() ?? "";
      final orderUid = result.order.uid.trim();
      if (authUrl.isEmpty || reference.isEmpty || orderUid.isEmpty) {
        DthFlushBar.instance.showError(
          title: "Checkout",
          message: "Could not start checkout. Please try again.",
        );
        return;
      }
      final payment = _PendingPayment(orderUid: orderUid, reference: reference);

      final returnedFromCallback = await MobileNavigationService.instance
          .navigateTo(
            AppWebView.path,
            extra: {
              RoutingArgumentKey.title: "Checkout",
              RoutingArgumentKey.initialURl: authUrl,
              RoutingArgumentKey.callbackUrl: result.callbackUrl,
              RoutingArgumentKey.showOpenInExternalBrowser: false,
            },
          );

      if (returnedFromCallback == true) {
        if (await _verifyWithRetry(reference)) {
          await _showPaid();
          return;
        }
        // Paystack reached the callback, so the customer has probably paid.
        // Do not abandon the order or allow a second charge: lock checkout,
        // remember the order, and tell them we are still confirming.
        _pending = payment;
        _quote = null;
        try {
          await _onCartRestored?.call();
        } catch (e, s) {
          _log.e("[checkout] cart refresh failed", error: e, stackTrace: s);
        }
        await MobileNavigationService.instance.navigateTo(
          StorePaymentResultView.path,
          extra: {
            RoutingArgumentKey.storePaymentSuccess: false,
            RoutingArgumentKey.storePaymentPending: true,
          },
        );
        return;
      }

      // Left payment without reaching the callback.
      await _settle(payment, confirmed: false);
    } on ApiFailure catch (e, s) {
      _log.e("[checkout] ApiFailure: ${e.message}", error: e, stackTrace: s);
      DthFlushBar.instance.showError(title: "Checkout", message: e.message);
    } catch (e, s) {
      _log.e("[checkout] unexpected", error: e, stackTrace: s);
      DthFlushBar.instance.showError(
        title: "Checkout",
        message: "Something went wrong confirming your payment.",
      );
    } finally {
      _placing = false;
      notifyListeners();
    }
  }

  /// `true` once verify succeeds; `false` if every attempt fails.
  Future<bool> _verifyWithRetry(String reference) async {
    for (var attempt = 0; ; attempt++) {
      try {
        await _repo.verifyPayment(reference: reference);
        return true;
      } catch (e, s) {
        _log.e(
          "[verify] attempt ${attempt + 1} failed",
          error: e,
          stackTrace: s,
        );
        if (attempt >= _verifyRetryDelays.length) return false;
        await Future<void>.delayed(_verifyRetryDelays[attempt]);
      }
    }
  }

  /// Resolves [payment]: success when [confirmed], otherwise abandon, which
  /// checks the provider first and reports an already-paid order.
  Future<void> _settle(
    _PendingPayment payment, {
    required bool confirmed,
  }) async {
    if (confirmed) {
      _pending = null;
      await _showPaid();
      return;
    }
    final leave = await _leavePayment(payment.orderUid);
    switch (leave) {
      case _LeavePaymentOutcome.paid:
        _pending = null;
        await _showPaid();
      case _LeavePaymentOutcome.restoredToCart:
        _pending = null;
        MobileNavigationService.instance.popUntil(NavigatorRoutes.storeCart);
      case _LeavePaymentOutcome.openOrders:
        _pending = null;
        MobileNavigationService.instance.popUntil(NavigatorRoutes.storeCart);
        await MobileNavigationService.instance.navigateTo(
          NavigatorRoutes.myOrders,
        );
      case _LeavePaymentOutcome.stayOnCheckout:
        // Still unknown. The next Pay settles this order again.
        _pending = payment;
    }
  }

  Future<void> _showPaid() async {
    try {
      await _onOrderPaid?.call();
    } catch (e, s) {
      _log.e("[checkout] cart clear failed", error: e, stackTrace: s);
    }
    await MobileNavigationService.instance.navigateTo(
      StorePaymentResultView.path,
      extra: {RoutingArgumentKey.storePaymentSuccess: true},
    );
  }

  /// Handles leave-payment / abandon, including typed API `event`s.
  Future<_LeavePaymentOutcome> _leavePayment(String orderUid) async {
    try {
      final abandon = await _repo.abandonOrder(orderUid);
      if (abandon.isPaid) return _LeavePaymentOutcome.paid;

      try {
        await _onCartRestored?.call();
      } catch (e, s) {
        _log.e("[checkout] cart restore failed", error: e, stackTrace: s);
      }
      _showAbandonFeedback(abandon);
      return _LeavePaymentOutcome.restoredToCart;
    } on ApiFailure catch (e, s) {
      _log.e("[abandon] ApiFailure: ${e.message}", error: e, stackTrace: s);
      final event = e.event?.toString().trim().toLowerCase() ?? "";
      switch (event) {
        case StoreAbandonEvents.orderAlreadyPaid:
          return _LeavePaymentOutcome.paid;
        case StoreAbandonEvents.orderNotAwaitingPayment:
          if (e.message.trim().isNotEmpty) {
            DthFlushBar.instance.showError(
              title: "Checkout",
              message: e.message,
            );
          }
          return _LeavePaymentOutcome.openOrders;
        case StoreAbandonEvents.orderNotFound:
          DthFlushBar.instance.showError(
            title: "Checkout",
            message: e.message.trim().isNotEmpty
                ? e.message
                : "Order not found.",
          );
          try {
            await _onCartRestored?.call();
          } catch (_) {}
          return _LeavePaymentOutcome.restoredToCart;
        case StoreAbandonEvents.paymentCheckFailed:
          DthFlushBar.instance.showError(
            title: "Checkout",
            message: e.message.trim().isNotEmpty
                ? e.message
                : "We could not check your payment. Try again.",
          );
          return _LeavePaymentOutcome.stayOnCheckout;
        default:
          DthFlushBar.instance.showError(title: "Checkout", message: e.message);
          return _LeavePaymentOutcome.stayOnCheckout;
      }
    }
  }

  void _showAbandonFeedback(StoreAbandonOrderResult abandon) {
    final base = abandon.message.trim().isNotEmpty
        ? abandon.message.trim()
        : "Your items are back in your cart.";
    final skippedLines = abandon.skipped
        .map((s) {
          final reason = s.reason.trim();
          if (reason.isNotEmpty) return reason;
          final name = s.name.trim();
          return name.isEmpty ? null : name;
        })
        .whereType<String>()
        .toList(growable: false);

    if (skippedLines.isEmpty) {
      DthFlushBar.instance.showSuccess(title: "Cart", message: base);
      return;
    }

    final message = "$base\n${skippedLines.join("\n")}";
    if (abandon.added > 0) {
      DthFlushBar.instance.showSuccess(title: "Cart", message: message);
    } else {
      DthFlushBar.instance.showError(title: "Cart", message: message);
    }
  }

  void reset() {
    _requestId++;
    _kind = null;
    _quote = null;
    _promoCode = null;
    _addressUid = null;
    _placing = false;
    _pending = null;
    changeBaseState(const ViewModelState.idle());
  }
}

enum _LeavePaymentOutcome { paid, restoredToCart, openOrders, stayOnCheckout }

class _PendingPayment {
  const _PendingPayment({required this.orderUid, required this.reference});

  final String orderUid;
  final String reference;
}

final storeCheckoutViewModelProvider =
    ChangeNotifierProvider<StoreCheckoutViewModel>((ref) {
      return StoreCheckoutViewModel(
        ref.read(storeRepositoryProvider),
        onOrderPaid: () =>
            ref.read(storeCartStateProvider).clearAfterCheckout(),
        onCartRestored: () =>
            ref.read(storeCartStateProvider).fetchCart(quiet: true),
      );
    });
