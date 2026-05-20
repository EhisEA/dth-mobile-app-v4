import "dart:async";
import "dart:ui" show ImageFilter;

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/subscription/components/subscription_widget.dart";
import "package:dth_v4/features/subscription/view_model/subscription_checkout_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SubscriptionView extends ConsumerStatefulWidget {
  const SubscriptionView({super.key});

  static const String path = NavigatorRoutes.subscription;

  @override
  ConsumerState<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends ConsumerState<SubscriptionView> {
  static const double _blurScrollRangePx = 200;

  final ValueNotifier<double> _listScrollOffsetPx = ValueNotifier<double>(0);

  @override
  void dispose() {
    _listScrollOffsetPx.dispose();
    super.dispose();
  }

  void _resetListScrollBlur() {
    if (_listScrollOffsetPx.value != 0) _listScrollOffsetPx.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionPlansStateProvider);
    final checkoutBusy = ref
        .watch(subscriptionCheckoutViewModelProvider)
        .isBaseBusy;

    return Loader.page(
      isLoading: checkoutBusy,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(ImageAssets.subscriptionBg),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ValueListenableBuilder<double>(
                valueListenable: _listScrollOffsetPx,
                builder: (context, offsetPx, _) {
                  final t = (offsetPx / _blurScrollRangePx).clamp(0.0, 1.0);
                  if (t <= 0) return const SizedBox.shrink();
                  return IgnorePointer(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 14 * t,
                          sigmaY: 14 * t,
                        ),
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.06 * t),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  subscriptionState.plans,
                  subscriptionState.fetchFailed,
                ]),
                builder: (context, _) {
                  final failed = subscriptionState.fetchFailed.value;
                  final plans = subscriptionState.plans.value;

                  if (failed && plans == null) {
                    _resetListScrollBlur();
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText.semiBold(
                              "Could not load subscription plans.",
                              fontSize: 14,
                              color: AppColors.white,
                              textAlign: TextAlign.center,
                            ),
                            Gap.h16,
                            AppButton.primary(
                              press: () =>
                                  unawaited(subscriptionState.fetchPlans()),
                              text: "Retry",
                              height: 48,
                            ),
                            Gap.h32,
                            Gap.h32,
                          ],
                        ),
                      ),
                    );
                  }
                  if (plans == null) {
                    _resetListScrollBlur();
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  if (plans.isEmpty) {
                    _resetListScrollBlur();
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AppText.regular(
                          "No subscription plans are available right now.",
                          fontSize: 14,
                          color: AppColors.black,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return SafeArea(
                    top: false,
                    child: SizedBox.expand(
                      child: SubscriptionWidget(
                        plans: plans,
                        listScrollOffsetPx: _listScrollOffsetPx,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
