import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class OrdersEmptyState extends ConsumerWidget {
  const OrdersEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              ImageAssets.storeEmptyState,
              height: 160,
              fit: BoxFit.contain,
            ),
            Gap.h20,
            AppText.medium(
              "Your Order History Is Empty",
              fontSize: 18,
              color: AppColors.mainBlack,
              textAlign: TextAlign.center,
            ),
            Gap.h8,
            AppText.regular(
              "Your orders will appear here once you make a purchase from the DTH Store.",
              fontSize: 14,
              height: 1.4,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
            ),
            Gap.h24,
            AppButton.onBorder(
              text: "Go to DTH Store",
              fontSize: 14,
              isShort: true,
              width: 180,
              borderColor: AppColors.primary,
              textColor: AppColors.primary,
              press: () {
                HapticFeedback.lightImpact();
                final modules =
                    ref.read(appModulesStateProvider).appModules.value;
                final path = modules?.merchStore == true
                    ? ShoppingComplexView.path
                    : LiveEventStoresView.path;
                MobileNavigationService.instance.navigateTo(path);
              },
            ),
          ],
        ),
      ),
    );
  }
}
