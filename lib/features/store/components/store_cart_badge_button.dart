import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreCartBadgeButton extends ConsumerWidget {
  const StoreCartBadgeButton({
    super.key,
    required this.kind,
    this.countOverride,
  });

  final StoreKind kind;

  /// Used only before cart state has been loaded/edited (seed from store).
  final int? countOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(storeCartStateProvider);
    final count = cart.isAuthoritative
        ? cart.countFor(kind)
        : (countOverride ?? cart.countFor(kind));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        MobileNavigationService.instance.navigateTo(
          StoreCartView.path,
          extra: {RoutingArgumentKey.storeCartKind: kind.name},
        );
      },
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: SvgPicture.asset(
                SvgAssets.shoppingBag,
                width: 36,
                height: 36,
              ),
            ),
            if (count > 0)
              Positioned(
                right: 2,
                top: 1,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.redTint35,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                  child: AppText.bold(
                    count > 99 ? "99+" : "$count",
                    centered: true,
                    color: AppColors.white,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
