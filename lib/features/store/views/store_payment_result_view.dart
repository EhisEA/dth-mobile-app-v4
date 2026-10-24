import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/orders/orders.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class StorePaymentResultView extends ConsumerStatefulWidget {
  const StorePaymentResultView({
    super.key,
    required this.isSuccess,
    this.isPending = false,
  });

  static const String path = NavigatorRoutes.storePaymentResult;

  final bool isSuccess;

  /// Paystack returned but the payment could not be confirmed yet. The screen
  /// rechecks in the background and on pull-to-refresh.
  final bool isPending;

  @override
  ConsumerState<StorePaymentResultView> createState() =>
      _StorePaymentResultViewState();
}

class _StorePaymentResultViewState
    extends ConsumerState<StorePaymentResultView> {
  static const _pollInterval = Duration(seconds: 10);

  /// About 2 minutes of background checks; pull-to-refresh still works after.
  static const _maxPolls = 12;

  Timer? _poll;
  int _polls = 0;

  bool get _isSuccess => widget.isSuccess;
  bool get _isPending => widget.isPending;

  @override
  void initState() {
    super.initState();
    if (_isPending) {
      _poll = Timer.periodic(_pollInterval, (_) => _onPoll());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _onPoll() {
    final checkout = ref.read(storeCheckoutViewModelProvider);
    // Settled (this screen was replaced), logged out, or out of attempts.
    if (!mounted || !checkout.hasPendingPayment || ++_polls > _maxPolls) {
      _poll?.cancel();
      return;
    }
    unawaited(checkout.recheckPendingPayment(quiet: true));
  }

  @override
  Widget build(BuildContext context) {
    final title = _isPending
        ? "Confirming Payment"
        : _isSuccess
        ? "Payment Successful"
        : "Payment Failed";
    final description = _isPending
        ? "We're still confirming your payment. This page updates on its own, or pull down to check now."
        : _isSuccess
        ? "Your order has been confirmed. We'll notify you when your item(s) have been shipped."
        : "We couldn't process your payment. Please try again or use a different payment method.";
    final cta = _isSuccess || _isPending ? "Go to orders" : "Try again";
    final bgAsset = _isSuccess || _isPending
        ? ImageAssets.storePaymentSuccessBg
        : ImageAssets.storePaymentFailedBg;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isPending)
            Icon(Icons.schedule_rounded, size: 140, color: AppColors.white)
          else if (_isSuccess)
            Image.asset(ImageAssets.confirmed, height: 160)
          else
            Image.asset(ImageAssets.storePaymentFailedIcon, height: 160),
          Gap.h28,
          AppText.semiBold(
            title,
            fontSize: 20,
            height: 1,
            color: AppColors.white,
            textAlign: TextAlign.center,
          ),
          Gap.h12,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppText.regular(
              description,
              fontSize: 16,
              height: 1.45,
              color: AppColors.white.withValues(alpha: 0.92),
              textAlign: TextAlign.center,
            ),
          ),
          Gap.h30,
          Gap.h30,
          Gap.h30,
        ],
      ),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage(bgAsset), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      unawaited(_onClose());
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xffC2FFE0).withValues(alpha: 0.09),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isPending
                    ? RefreshIndicator(
                        onRefresh: () => ref
                            .read(storeCheckoutViewModelProvider)
                            .recheckPendingPayment(),
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: content,
                                ),
                              ),
                        ),
                      )
                    : content,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: AppButton.onBorder(
                  text: cta,
                  fontSize: 15,
                  color: Colors.transparent,
                  borderColor: AppColors.white,
                  textColor: AppColors.white,
                  press: () {
                    HapticFeedback.lightImpact();
                    unawaited(_onPrimaryAction());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ensureCartCleared() async {
    if (!_isSuccess) return;
    await ref.read(storeCartStateProvider).clearAfterCheckout();
  }

  Future<void> _openOrders() async {
    MobileNavigationService.instance.popUntil(StoreCartView.path);
    await MobileNavigationService.instance.navigateTo(MyOrdersView.path);
  }

  Future<void> _onClose() async {
    if (_isPending) {
      MobileNavigationService.instance.popUntil(StoreCartView.path);
      return;
    }
    if (_isSuccess) {
      await _ensureCartCleared();
      MobileNavigationService.instance.popUntil(StoreCartView.path);
      return;
    }
    MobileNavigationService.instance.goBack();
  }

  Future<void> _onPrimaryAction() async {
    if (_isSuccess || _isPending) {
      await _ensureCartCleared();
      await _openOrders();
      return;
    }
    MobileNavigationService.instance.goBack();
  }
}
