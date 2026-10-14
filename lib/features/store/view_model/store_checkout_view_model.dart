import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/store/views/store_payment_result_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreCheckoutViewModel extends BaseChangeNotifierViewModel {
  StoreCheckoutViewModel(this._repo, {Future<void> Function()? onOrderPaid})
    : _onOrderPaid = onOrderPaid;

  final StoreRepo _repo;
  final Future<void> Function()? _onOrderPaid;
  final _log = const AppLogger(StoreCheckoutViewModel);

  StoreKind? _kind;
  StoreCheckoutQuote? _quote;
  String? _promoCode;
  String? _addressUid;
  int _requestId = 0;
  bool _placing = false;

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

  /// Re-quote after the user applies (or clears) a promo code.
  Future<void> applyPromo(String code) async {
    final trimmed = code.trim();
    _promoCode = trimmed.isEmpty ? null : trimmed;
    await fetchQuote();
    final promo = _quote?.promo;
    if (promo == null) return;
    if (promo.applied) {
      DthFlushBar.instance.showSuccess(
        title: "Promo",
        message: promo.message?.trim().isNotEmpty == true
            ? promo.message!
            : "Promo code applied.",
      );
    } else if (promo.message != null && promo.message!.trim().isNotEmpty) {
      DthFlushBar.instance.showError(title: "Promo", message: promo.message!);
    }
  }

  /// Keep [uid] for the next quote / checkout (Merch Store delivery address).
  void setAddressUid(String? uid) {
    final next = uid?.trim();
    _addressUid = (next == null || next.isEmpty) ? null : next;
  }

  /// Call after the shipping address screen closes.
  Future<void> onAddressChanged({String? addressUid}) async {
    if (addressUid != null) setAddressUid(addressUid);
    await fetchQuote();
  }

  /// Create the order, open Paystack when needed, verify, then result screen.
  Future<void> placeOrder() async {
    final kind = _kind;
    if (kind == null || !canCheckout || _placing) return;

    _placing = true;
    notifyListeners();
    try {
      final result = await _repo.checkout(
        kind.apiStoreId,
        promoCode: _promoCode,
        addressUid: _addressUid,
      );

      var paymentSucceeded = false;

      if (!result.requiresPayment) {
        paymentSucceeded = true;
      } else {
        final authUrl = result.authorizationUrl?.trim() ?? "";
        final reference = result.reference?.trim() ?? "";
        if (authUrl.isEmpty || reference.isEmpty) {
          DthFlushBar.instance.showError(
            title: "Checkout",
            message: "Could not start checkout. Please try again.",
          );
          return;
        }

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

        paymentSucceeded = returnedFromCallback == true;
        if (paymentSucceeded) {
          await _repo.verifyPayment(reference: reference);
        }
      }

      if (paymentSucceeded) {
        try {
          await _onOrderPaid?.call();
        } catch (e, s) {
          _log.e("[checkout] cart clear failed", error: e, stackTrace: s);
        }
      }

      await MobileNavigationService.instance.navigateTo(
        StorePaymentResultView.path,
        extra: {RoutingArgumentKey.storePaymentSuccess: paymentSucceeded},
      );
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

  void reset() {
    _requestId++;
    _kind = null;
    _quote = null;
    _promoCode = null;
    _addressUid = null;
    _placing = false;
    changeBaseState(const ViewModelState.idle());
  }
}

final storeCheckoutViewModelProvider =
    ChangeNotifierProvider<StoreCheckoutViewModel>((ref) {
      return StoreCheckoutViewModel(
        ref.read(storeRepositoryProvider),
        onOrderPaid: () =>
            ref.read(storeCartStateProvider).clearAfterCheckout(),
      );
    });
