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

class StorePaymentResultView extends ConsumerWidget {
  const StorePaymentResultView({super.key, required this.isSuccess});

  static const String path = NavigatorRoutes.storePaymentResult;

  final bool isSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = isSuccess ? "Payment Successful" : "Payment Failed";
    final description = isSuccess
        ? "Your order has been confirmed. We'll notify you when your item(s) have been shipped."
        : "We couldn't process your payment. Please try again or use a different payment method.";
    final cta = isSuccess ? "Go to orders" : "Try again";
    final bgAsset = isSuccess
        ? ImageAssets.storePaymentSuccessBg
        : ImageAssets.storePaymentFailedBg;

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
                      unawaited(_onClose(ref));
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSuccess)
                        Image.asset(ImageAssets.confirmed, height: 160)
                      else
                        Image.asset(
                          ImageAssets.storePaymentFailedIcon,
                          height: 160,
                        ),
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
                ),
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
                    unawaited(_onPrimaryAction(ref));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ensureCartCleared(WidgetRef ref) async {
    if (!isSuccess) return;
    await ref.read(storeCartStateProvider).clearAfterCheckout();
  }

  Future<void> _onClose(WidgetRef ref) async {
    if (isSuccess) {
      await _ensureCartCleared(ref);
      MobileNavigationService.instance.popUntil(StoreCartView.path);
      return;
    }
    MobileNavigationService.instance.goBack();
  }

  Future<void> _onPrimaryAction(WidgetRef ref) async {
    if (isSuccess) {
      await _ensureCartCleared(ref);
      MobileNavigationService.instance.popUntil(StoreCartView.path);
      await MobileNavigationService.instance.navigateTo(MyOrdersView.path);
      return;
    }
    MobileNavigationService.instance.goBack();
  }
}
