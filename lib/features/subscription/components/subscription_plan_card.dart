import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/int_extension.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    this.activePlan,
    required this.onCTATap,
    this.isCheckoutBusy = false,
  });

  final SubscriptionModel plan;

  /// Plan the user is subscribed to, if any (from the plans list).
  final SubscriptionModel? activePlan;
  final VoidCallback onCTATap;
  final bool isCheckoutBusy;

  @override
  Widget build(BuildContext context) {
    final perks = featureLines(plan);
    final active = activePlan;
    final isSubscribed = active != null && plan.uid == active.uid;
    final tierVsActive = active == null
        ? null
        : compareSubscriptionPlanTier(plan, active);
    final subscribeLabel = "Subscribe to ${plan.name}";
    final upgradeLabel = "Upgrade to ${plan.name}";
    const coveredLabel = "You have an active subscription";
    final priceLabel = plan.amount.toMoneyWholeNumber();
    final currencySymbol = _currencySymbol(plan);
    const periodSuffix = " /per season";
    final badgeColor = _tagBadgeBackground(plan);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.greyTint15,
          border: Border.all(color: AppColors.greyTint30),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.greyTint35),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.tag != null && plan.tag!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(500),
                      ),
                      child: AppText.semiBold(
                        plan.tag!.toUpperCase(),
                        fontSize: 8,
                        letterSpacing: 0.5,
                        color: AppColors.white,
                      ),
                    ),
                    Gap.h16,
                  ],
                  AppText.regular(
                    plan.name,
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                  Gap.h2,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AppText.matterBold(
                        currencySymbol,
                        fontSize: 14,
                        color: AppColors.mainBlack,
                        height: 0,
                      ),
                      AppText.matterBold(
                        priceLabel,
                        fontSize: 26,
                        color: AppColors.mainBlack,
                        height: 0,
                      ),
                      AppText.regular(
                        periodSuffix,
                        fontSize: 12,
                        color: AppColors.tint15,
                      ),
                    ],
                  ),
                  Gap.h16,
                  if (isSubscribed)
                    AppButton.primary(
                      press: () {},
                      text: "Subscribed",
                      height: 48,
                      enabled: true,
                    )
                  else if (tierVsActive != null && tierVsActive < 0)
                    AppButton.onBorder(
                      press: () {},
                      text: coveredLabel,
                      height: 48,
                    )
                  else if (tierVsActive != null && tierVsActive > 0)
                    AppButton.onBorder(
                      press: onCTATap,
                      text: upgradeLabel,
                      height: 48,
                    )
                  else
                    AppButton.onBorder(
                      press: onCTATap,
                      text: subscribeLabel,
                      height: 48,
                    ),
                ],
              ),
            ),
            Gap.h16,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AppText.regular(
                "What's included",
                fontSize: 12,
                color: AppColors.tint25,
              ),
            ),
            Gap.h12,
            ...perks.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(SvgAssets.check),
                    Gap.w12,
                    Expanded(
                      child: AppText.regular(
                        line,
                        fontSize: 13,
                        color: AppColors.black,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _tagBadgeBackground(SubscriptionModel plan) {
  final tag = plan.tag?.toLowerCase() ?? "";
  if (tag.contains("popular") || tag.contains("recommend")) {
    return AppColors.secondaryOrange;
  }
  if (tag.contains("best") || tag.contains("value")) {
    return AppColors.secondaryBlue;
  }
  return AppColors.secondaryBlue;
}

List<String> featureLines(SubscriptionModel plan) {
  return plan.features.map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
}

String _currencySymbol(SubscriptionModel plan) {
  switch (plan.currency.toUpperCase()) {
    case "USD":
      return "\$";
    default:
      return "₦";
  }
}
