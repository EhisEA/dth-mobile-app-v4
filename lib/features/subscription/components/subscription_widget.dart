import "dart:async";

import "package:dth_v4/data/models/subscription_model.dart";
import "package:dth_v4/features/subscription/components/subscription_plan_card.dart";
import "package:dth_v4/features/subscription/view_model/subscription_checkout_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SubscriptionWidget extends ConsumerWidget {
  const SubscriptionWidget({super.key, required this.plans});

  final List<SubscriptionModel> plans;

  /// Sheet height as a fraction of the parent; scroll expands toward [maxChildSize].
  static const double _initialSheetFraction = 0.70;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutVm = ref.watch(subscriptionCheckoutViewModelProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scrollEndPadding = bottomInset + 70;

    SubscriptionModel? activePlan;
    for (final p in plans) {
      if (p.isActiveSubscription) {
        activePlan = p;
        break;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: _initialSheetFraction,
      minChildSize: _initialSheetFraction,
      maxChildSize: 1.0,
      snap: true,
      builder: (context, scrollController) {
        return ListView.separated(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 0, 16, scrollEndPadding),
          itemCount: plans.length,
          separatorBuilder: (_, __) => Gap.h16,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return SubscriptionPlanCard(
              plan: plan,
              activePlan: activePlan,
              isCheckoutBusy: checkoutVm.isBaseBusy,
              onCTATap: () {
                if (activePlan != null && plan.uid == activePlan.uid) return;
                if (activePlan != null &&
                    compareSubscriptionPlanTier(plan, activePlan) < 0) {
                  return;
                }
                unawaited(checkoutVm.purchasePlan(plan));
                HapticFeedback.lightImpact();
              },
            );
          },
        );
      },
    );
  }
}
