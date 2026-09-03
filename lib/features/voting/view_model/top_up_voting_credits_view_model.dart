import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/int_extension.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/voting/models/vote_credit_quote.dart";
import "package:dth_v4/features/voting/models/voting_credit_info.dart";
import "package:dth_v4/features/voting/view_model/voting_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:intl/intl.dart";

enum TopUpInputMode { amount, credits }

class TopUpVotingCreditsViewModel extends BaseChangeNotifierViewModel {
  TopUpVotingCreditsViewModel(
    this._repo,
    this._refreshVotingCredits,
    this._refreshProfile,
    this._creditInfo,
  );

  final VotingRepo _repo;
  final Future<void> Function(int purchasedQuantity) _refreshVotingCredits;
  final Future<void> Function() _refreshProfile;
  final VotingCreditInfo Function() _creditInfo;

  VotingCreditInfo get creditInfo => _creditInfo();

  static const _quoteDebounce = Duration(milliseconds: 400);

  static const _quoteKey = "topUpQuote";
  static const _purchaseKey = "topUpPurchase";

  Timer? _quoteTimer;
  int _quoteRequestId = 0;

  TopUpInputMode inputMode = TopUpInputMode.amount;
  int amount = 0;
  int credits = 0;
  VoteCreditQuote? quote;

  int get inputValue => inputMode == TopUpInputMode.amount ? amount : credits;

  bool get hasInput => inputValue > 0;

  ViewModelState get quoteState =>
      getState(_quoteKey) ?? const ViewModelState.idle();

  ViewModelState get purchaseState =>
      getState(_purchaseKey) ?? const ViewModelState.idle();

  bool get isPurchaseBusy => purchaseState.isBusy;

  bool get isAmountInRange => creditInfo.isAmountInRange(amount);

  bool get isCreditsInRange => creditInfo.isCreditInRange(credits);

  bool get isQuoteInRange =>
      quote != null && creditInfo.isCreditInRange(quote!.quantity);

  bool get isQuotedAmountInRange =>
      quote != null && creditInfo.isAmountInRange(quote!.amount);

  bool get canProceed {
    if (quoteState.isBusy || isPurchaseBusy || quote == null) return false;
    return switch (inputMode) {
      TopUpInputMode.amount => isAmountInRange && isQuoteInRange,
      TopUpInputMode.credits => isCreditsInRange && isQuotedAmountInRange,
    };
  }

  String? get amountValidationMessage {
    if (inputMode == TopUpInputMode.amount) {
      if (amount <= 0) return null;
      if (amount < creditInfo.minAmount) {
        return "Minimum top up is ${creditInfo.minAmount.toMoneyWholeNumber(symbol: "₦")}";
      }
      if (amount > creditInfo.maxAmount) {
        return "Maximum top up is ${creditInfo.maxAmount.toMoneyWholeNumber(symbol: "₦")}";
      }
      if (quote != null && !creditInfo.isCreditInRange(quote!.quantity)) {
        return "Credits must be between ${creditInfo.minCredit} and ${creditInfo.maxCredit}";
      }
      return null;
    }

    if (credits <= 0) return null;
    if (credits < creditInfo.minCredit) {
      return "Minimum top up is ${creditInfo.minCredit} credits";
    }
    if (credits > creditInfo.maxCredit) {
      return "Maximum top up is ${creditInfo.maxCredit} credits";
    }
    if (quote != null && !creditInfo.isAmountInRange(quote!.amount)) {
      return "Amount must be between ${creditInfo.minAmount.toMoneyWholeNumber(symbol: "₦")} and ${creditInfo.maxAmount.toMoneyWholeNumber(symbol: "₦")}";
    }
    return null;
  }

  String get currencySymbol => quote?.currencySymbol ?? "₦";

  String get formattedAmountDisplay {
    if (amount <= 0) return "0";
    return amount.toMoneyWholeNumber();
  }

  String get formattedCreditsDisplay {
    if (credits <= 0) return "0";
    return NumberFormat.decimalPattern().format(credits);
  }

  String get proceedLabel {
    if (!canProceed || quote == null) {
      return inputMode == TopUpInputMode.amount
          ? "Enter amount to proceed"
          : "Enter credits to proceed";
    }
    final payAmount = quote!.amount.toMoneyWholeNumber();
    return "Proceed to pay $currencySymbol$payAmount";
  }

  void setInputMode(TopUpInputMode mode) {
    if (inputMode == mode) return;
    inputMode = mode;
    if (quote != null) {
      if (mode == TopUpInputMode.credits) {
        credits = quote!.quantity;
      } else {
        amount = quote!.amount;
      }
    }
    quote = null;
    setState(_quoteKey, const ViewModelState.idle());
    notifyListeners();
    _scheduleQuote();
  }

  void setAmountDigits(String rawDigits) {
    final digits = rawDigits.replaceAll(RegExp(r"[^0-9]"), "");
    var next = digits.isEmpty ? 0 : int.tryParse(digits) ?? 0;
    if (creditInfo.maxAmount > 0 && next > creditInfo.maxAmount) {
      next = creditInfo.maxAmount;
    }
    if (next == amount) return;
    amount = next;
    quote = null;
    setState(_quoteKey, const ViewModelState.idle());
    notifyListeners();
    _scheduleQuote();
  }

  void setCreditsDigits(String rawDigits) {
    final digits = rawDigits.replaceAll(RegExp(r"[^0-9]"), "");
    var next = digits.isEmpty ? 0 : int.tryParse(digits) ?? 0;
    if (creditInfo.maxCredit > 0 && next > creditInfo.maxCredit) {
      next = creditInfo.maxCredit;
    }
    if (next == credits) return;
    credits = next;
    quote = null;
    setState(_quoteKey, const ViewModelState.idle());
    notifyListeners();
    _scheduleQuote();
  }

  void _scheduleQuote() {
    _quoteTimer?.cancel();
    final shouldQuote = switch (inputMode) {
      TopUpInputMode.amount => isAmountInRange,
      TopUpInputMode.credits => isCreditsInRange,
    };
    if (!shouldQuote) return;
    _quoteTimer = Timer(_quoteDebounce, () {
      unawaited(_fetchQuote());
    });
  }

  Future<void> _fetchQuote() async {
    final requestAmount = amount;
    final requestCredits = credits;
    final shouldFetch = switch (inputMode) {
      TopUpInputMode.amount => creditInfo.isAmountInRange(requestAmount),
      TopUpInputMode.credits => creditInfo.isCreditInRange(requestCredits),
    };
    if (!shouldFetch) return;

    final requestId = ++_quoteRequestId;
    setState(_quoteKey, const ViewModelState.busy());
    try {
      final result = await _repo.quoteCredits(
        amount: inputMode == TopUpInputMode.amount ? requestAmount : null,
        quantity: inputMode == TopUpInputMode.credits ? requestCredits : null,
      );
      if (requestId != _quoteRequestId) return;
      if (inputMode == TopUpInputMode.amount && requestAmount != amount) {
        return;
      }
      if (inputMode == TopUpInputMode.credits && requestCredits != credits) {
        return;
      }
      quote = result;
      setState(_quoteKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      if (requestId != _quoteRequestId) return;
      if (inputMode == TopUpInputMode.amount && requestAmount != amount) {
        return;
      }
      if (inputMode == TopUpInputMode.credits && requestCredits != credits) {
        return;
      }
      quote = null;
      setState(_quoteKey, ViewModelState.error(e));
      DthFlushBar.instance.showError(title: "Top up", message: e.message);
    }
  }

  Future<void> purchase({VoidCallback? onCheckoutReady}) async {
    if (!canProceed || quote == null) return;
    final quantity = quote!.quantity;
    setState(_purchaseKey, const ViewModelState.busy());
    try {
      final data = await _repo.purchaseCredits(quantity: quantity);
      if (data.authorizationUrl.isEmpty || data.reference.isEmpty) {
        setState(_purchaseKey, const ViewModelState.idle());
        DthFlushBar.instance.showError(
          title: "Top up",
          message: "Could not start checkout. Please try again.",
        );
        return;
      }

      onCheckoutReady?.call();

      final returnedFromCallback = await MobileNavigationService.instance
          .navigateTo(
            AppWebView.path,
            extra: {
              RoutingArgumentKey.title: "Top up credits",
              RoutingArgumentKey.initialURl: data.authorizationUrl,
              RoutingArgumentKey.callbackUrl: data.callbackUrl,
              RoutingArgumentKey.showOpenInExternalBrowser: false,
            },
          );

      final paymentSucceeded = returnedFromCallback == true;
      if (paymentSucceeded) {
        await _repo.verifyPayment(reference: data.reference);
        await Future.wait([
          _refreshVotingCredits(quantity),
          _refreshProfile(),
        ]);
        final creditsLabel = NumberFormat.decimalPattern().format(quantity);
        DthFlushBar.instance.showSuccess(
          title: "Payment Successful",
          message:
              "$creditsLabel voting credits have been added to your account.",
        );
      } else {
        DthFlushBar.instance.showError(
          title: "Payment Failed",
          message:
              "We couldn't process your payment. Please try again or use a different method.",
        );
      }

      setState(_purchaseKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      setState(_purchaseKey, ViewModelState.error(e));
      DthFlushBar.instance.showError(title: "Top up", message: e.message);
    } catch (e) {
      setState(_purchaseKey, ViewModelState.error(ApiFailure(e.toString())));
      DthFlushBar.instance.showError(
        title: "Top up",
        message: "Something went wrong confirming your payment.",
      );
    }
  }

  void reset() {
    _quoteTimer?.cancel();
    _quoteRequestId++;
    inputMode = TopUpInputMode.amount;
    amount = 0;
    credits = 0;
    quote = null;
    setState(_quoteKey, const ViewModelState.idle());
    setState(_purchaseKey, const ViewModelState.idle());
    notifyListeners();
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }
}

final topUpVotingCreditsViewModelProvider =
    ChangeNotifierProvider<TopUpVotingCreditsViewModel>((ref) {
      return TopUpVotingCreditsViewModel(
        ref.read(votingRepositoryProvider),
        (quantity) => ref
            .read(votingViewModelProvider)
            .refreshCreditsAfterPurchase(quantity),
        () => ref.read(userStateProvider).getUserDetailsFromServer(),
        () => ref.read(votingViewModelProvider).creditInfo,
      );
    });
