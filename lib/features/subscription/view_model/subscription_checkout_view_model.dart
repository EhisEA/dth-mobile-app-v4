import "dart:async";

import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/livestream/view_model/active_livestream_provider.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/subscription/views/confirmation_view.dart";
import "package:dth_v4/features/voting/view_model/voting_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Paystack subscription checkout: purchase → WebView → verify → refresh plans.
class SubscriptionCheckoutViewModel extends BaseChangeNotifierViewModel {
  SubscriptionCheckoutViewModel(
    this._repo,
    this._subscriptionPlansState,
    this._userState,
    this._invalidateActiveLivestream,
    this._refreshVoting,
  );

  final SubscriptionRepo _repo;
  final SubscriptionPlansState _subscriptionPlansState;
  final UserProfileState _userState;
  final void Function() _invalidateActiveLivestream;
  final Future<void> Function() _refreshVoting;

  Future<void> purchasePlan(SubscriptionModel plan) async {
    if (plan.isActiveSubscription) return;

    try {
      changeBaseState(const ViewModelState.busy());
      final response = await _repo.purchaseSubscription(planUid: plan.uid);
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
              RoutingArgumentKey.title: "Subscribe",
              RoutingArgumentKey.initialURl: data.authorizationUrl,
              RoutingArgumentKey.callbackUrl: data.callbackUrl,
              RoutingArgumentKey.showOpenInExternalBrowser: false,
            },
          );

      final paymentSucceeded = returnedFromCallback == true;
      if (paymentSucceeded) {
        await _repo.verifyPayment(reference: data.reference);
        await _subscriptionPlansState.fetchPlans();
        await _userState.getUserDetails();
        _invalidateActiveLivestream();
        // Subscribing can grant/unlock voting credits — refresh the voting week
        // so the tab reflects the new balance without waiting for its timer.
        unawaited(_refreshVoting());
        DthFlushBar.instance.showSuccess(
          title: "Subscription",
          message: "Your payment was confirmed.",
        );
      }

      await MobileNavigationService.instance.push(
        ConfirmationView.path,
        extra: {
          RoutingArgumentKey.confirmationSuccess: paymentSucceeded,
          RoutingArgumentKey.confirmationFlow: ConfirmationFlow.subscription,
          RoutingArgumentKey.confirmationSuccessDescription:
              "Your payment was successful. You now have pro access to DTH 5.",
          RoutingArgumentKey.confirmationFailureDescription:
              "We couldn't process your payment. Please try again or use a different method.",
        },
      );

      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e, s) {
      // ignore: avoid_print
      print("[checkout] ApiFailure: ${e.message}\n$s");
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(title: "Error", message: e.message);
    } catch (e, s) {
      // ignore: avoid_print
      print("[checkout] NON-ApiFailure: $e (${e.runtimeType})\n$s");
      // A non-ApiFailure (e.g. verify/parse/timeout) must not leave the VM
      // stuck busy after a real payment — reset state and surface an error.
      changeBaseState(ViewModelState.error(ApiFailure(e.toString())));
      DthFlushBar.instance.showError(
        title: "Error",
        message: "Something went wrong confirming your payment.",
      );
    }
  }
}

final subscriptionCheckoutViewModelProvider =
    ChangeNotifierProvider<SubscriptionCheckoutViewModel>((ref) {
      // Read the voting VM eagerly here (ref is valid at create time). Doing a
      // lazy `ref.read` inside the callback risks throwing when invoked later
      // mid-payment, which would land in purchasePlan's catch.
      final votingViewModel = ref.read(votingViewModelProvider);
      return SubscriptionCheckoutViewModel(
        ref.read(subscriptionRepositoryProvider),
        ref.read(subscriptionPlansStateProvider),
        ref.read(userStateProvider),
        () => ref.invalidate(activeLivestreamProvider),
        votingViewModel.silentRefresh,
      );
    });
