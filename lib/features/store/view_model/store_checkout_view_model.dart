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

  /// Bumped by [reset] (including logout). A payment flow that was waiting
  /// when it changed stops instead of writing the previous session's state.
  int _session = 0;

  /// A Paystack order whose payment could not be confirmed either way. While
  /// set, Pay settles this order instead of starting a second checkout. Scoped
  /// to the current checkout: [load] and logout clear it via [reset], so a
  /// later checkout for another cart or store never settles it by mistake.
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
    reset();
    _kind = kind;
    if (addressUid != null) setAddressUid(addressUid);
    return fetchQuote();
  }

  Future<bool> fetchQuote({bool showError = true}) async {
    final kind = _kind;
    if (kind == null) return false;

    final outcome = await _requestQuote(
      kind,
      promoCode: _promoCode,
      fallbackMessage: "Could not load checkout. Please try again.",
    );
    if (outcome == null) return false;
    final (:quote, :failure) = outcome;
    if (quote == null) {
      _quote = null;
      changeBaseState(ViewModelState.error(failure!));
      if (showError) {
        DthFlushBar.instance.showError(
          title: "Checkout",
          message: failure.message,
        );
      }
      return false;
    }
    _acceptQuote(quote);
    return true;
  }

  /// Quote with [code] and keep it only if the server applies it. On
  /// rejection or error the current promo, quote and state stay as they were.
  Future<void> applyPromo(String code) async {
    final kind = _kind;
    if (kind == null) return;
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      _promoCode = null;
      await fetchQuote();
      return;
    }

    final previousState = baseState;
    final outcome = await _requestQuote(
      kind,
      promoCode: trimmed,
      fallbackMessage: "Could not apply promo. Please try again.",
    );
    if (outcome == null) return;
    final (:quote, :failure) = outcome;
    final promo = quote?.promo;
    if (quote == null || promo == null || !promo.applied) {
      changeBaseState(previousState);
      final message = failure?.message ?? promo?.message?.trim() ?? "";
      DthFlushBar.instance.showError(
        title: "Promo",
        message: message.isNotEmpty
            ? message
            : "This promo code can't be applied.",
      );
      return;
    }
    _promoCode = trimmed;
    _acceptQuote(quote);
    final message = promo.message?.trim() ?? "";
    DthFlushBar.instance.showSuccess(
      title: "Promo",
      message: message.isNotEmpty ? message : "Promo code applied.",
    );
  }

  /// One quote request for the current address. Returns null when a newer
  /// request superseded it; otherwise exactly one of `quote` or `failure`.
  /// Leaves the view model busy for the caller to settle.
  Future<({StoreCheckoutQuote? quote, ApiFailure? failure})?> _requestQuote(
    StoreKind kind, {
    required String? promoCode,
    required String fallbackMessage,
  }) async {
    final requestId = ++_requestId;
    changeBaseState(const ViewModelState.busy());
    try {
      final result = await _repo.quoteCheckout(
        kind.apiStoreId,
        promoCode: promoCode,
        addressUid: _addressUid,
      );
      if (requestId != _requestId) return null;
      return (quote: result, failure: null);
    } on ApiFailure catch (e, s) {
      if (requestId != _requestId) return null;
      _log.e("[quote] ApiFailure: ${e.message}", error: e, stackTrace: s);
      return (quote: null, failure: e);
    } catch (e, s) {
      if (requestId != _requestId) return null;
      _log.e("[quote] unexpected", error: e, stackTrace: s);
      return (quote: null, failure: ApiFailure(fallbackMessage));
    }
  }

  void _acceptQuote(StoreCheckoutQuote quote) {
    _quote = quote;
    final quotedUid = quote.address?.uid.trim();
    if (quotedUid != null && quotedUid.isNotEmpty) {
      _addressUid = quotedUid;
    }
    changeBaseState(const ViewModelState.idle());
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

    final session = _session;
    _placing = true;
    notifyListeners();
    try {
      if (pending != null) {
        // An earlier payment is unresolved. Settle it before charging again.
        final verify = await _verifyWithRetry(pending.reference);
        if (session != _session) return;
        await _settle(pending, verify, session);
        return;
      }

      final result = await _repo.checkout(
        kind.apiStoreId,
        promoCode: _promoCode,
        addressUid: _addressUid,
      );
      if (session != _session) return;

      if (!result.requiresPayment) {
        await _showPaid(session);
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
      if (session != _session) return;

      if (returnedFromCallback == true) {
        final verify = await _verifyWithRetry(reference);
        if (session != _session) return;
        if (verify != _VerifyResult.unknown) {
          await _settle(payment, verify, session);
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
        if (session != _session) return;
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
      await _settle(payment, _VerifyResult.unknown, session);
    } on ApiFailure catch (e, s) {
      _log.e("[checkout] ApiFailure: ${e.message}", error: e, stackTrace: s);
      if (session != _session) return;
      DthFlushBar.instance.showError(title: "Checkout", message: e.message);
    } catch (e, s) {
      _log.e("[checkout] unexpected", error: e, stackTrace: s);
      if (session != _session) return;
      DthFlushBar.instance.showError(
        title: "Checkout",
        message: "Something went wrong confirming your payment.",
      );
    } finally {
      _placing = false;
      notifyListeners();
    }
  }

  /// Verify contract: 200 means paid. A client error (4xx) means the backend
  /// checked and the payment did not succeed. Anything else (no connection,
  /// timeout, 5xx, rate limit) is retried, then reported as unknown.
  Future<_VerifyResult> _verifyWithRetry(String reference) async {
    for (var attempt = 0; ; attempt++) {
      try {
        await _repo.verifyPayment(reference: reference);
        return _VerifyResult.paid;
      } on ApiFailure catch (e, s) {
        _log.e(
          "[verify] attempt ${attempt + 1} failed",
          error: e,
          stackTrace: s,
        );
        if (_isDefiniteDecline(e)) return _VerifyResult.failed;
      } catch (e, s) {
        _log.e(
          "[verify] attempt ${attempt + 1} failed",
          error: e,
          stackTrace: s,
        );
      }
      if (attempt >= _verifyRetryDelays.length) return _VerifyResult.unknown;
      await Future<void>.delayed(_verifyRetryDelays[attempt]);
    }
  }

  static bool _isDefiniteDecline(ApiFailure e) {
    final code = e.statusCode;
    if (code == null || code < 400 || code >= 500) return false;
    // Auth, timeout and rate-limit errors say nothing about the payment.
    return code != 401 && code != 403 && code != 408 && code != 429;
  }

  /// Resolves [payment] from [verify]. Paid shows success. Otherwise abandon,
  /// which checks the provider first and reports an already-paid order.
  Future<void> _settle(
    _PendingPayment payment,
    _VerifyResult verify,
    int session,
  ) async {
    if (verify == _VerifyResult.paid) {
      _pending = null;
      await _showPaid(session);
      return;
    }
    final leave = await _leavePayment(payment.orderUid, session);
    if (leave == null) return;
    switch (leave) {
      case _LeavePaymentOutcome.paid:
        _pending = null;
        await _showPaid(session);
      case _LeavePaymentOutcome.restoredToCart:
        _pending = null;
        MobileNavigationService.instance.popUntil(NavigatorRoutes.storeCart);
        if (verify == _VerifyResult.failed) {
          await MobileNavigationService.instance.navigateTo(
            StorePaymentResultView.path,
            extra: {RoutingArgumentKey.storePaymentSuccess: false},
          );
        }
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

  Future<void> _showPaid(int session) async {
    try {
      await _onOrderPaid?.call();
    } catch (e, s) {
      _log.e("[checkout] cart clear failed", error: e, stackTrace: s);
    }
    if (session != _session) return;
    await MobileNavigationService.instance.navigateTo(
      StorePaymentResultView.path,
      extra: {RoutingArgumentKey.storePaymentSuccess: true},
    );
  }

  /// Handles leave-payment / abandon, including typed API `event`s.
  /// Returns null when the session changed (logout) while abandoning.
  Future<_LeavePaymentOutcome?> _leavePayment(
    String orderUid,
    int session,
  ) async {
    try {
      final abandon = await _repo.abandonOrder(orderUid);
      if (session != _session) return null;
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
      if (session != _session) return null;
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
    _session++;
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

enum _VerifyResult { paid, failed, unknown }

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
