import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/subscription/views/confirmation_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Paystack subscription checkout: purchase → WebView → verify → refresh plans.
class SubscriptionCheckoutViewModel extends BaseChangeNotifierViewModel {
  SubscriptionCheckoutViewModel(
    this._repo,
    this._subscriptionPlansState,
    this._userState,
  );

  final SubscriptionRepo _repo;
  final SubscriptionPlansState _subscriptionPlansState;
  final UserProfileState _userState;

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
            },
          );

      final paymentSucceeded = returnedFromCallback == true;
      if (paymentSucceeded) {
        await _repo.verifyPayment(reference: data.reference);
        await _subscriptionPlansState.fetchPlans();
        await _userState.getUserDetails();
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
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
      DthFlushBar.instance.showError(title: "Error", message: e.message);
    }
  }
}

final subscriptionCheckoutViewModelProvider =
    ChangeNotifierProvider<SubscriptionCheckoutViewModel>((ref) {
      return SubscriptionCheckoutViewModel(
        ref.read(subscriptionRepositoryProvider),
        ref.read(subscriptionPlansStateProvider),
        ref.read(userStateProvider),
      );
    });
