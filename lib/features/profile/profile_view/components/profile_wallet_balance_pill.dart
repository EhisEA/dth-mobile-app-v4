import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Profile wallet bar under email — balance + optional Withdraw (Figma).
class ProfileWalletBalancePill extends StatelessWidget {
  const ProfileWalletBalancePill({
    super.key,
    required this.user,
    this.showWithdraw = true,
    this.onWithdraw,
  });

  final UserModel user;
  final bool showWithdraw;
  final VoidCallback? onWithdraw;

  static const _withdrawOverhang = 40.0;

  @override
  Widget build(BuildContext context) {
    final balance = user.walletBalance ?? const WalletBalance();

    final balanceBar = Container(
      padding: EdgeInsets.fromLTRB(10, 12, showWithdraw ? 38 : 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xff202020),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(SvgAssets.wallet, width: 18, height: 18),
          Gap.w8,
          AppText.semiBold(
            balance.formattedLabel,
            fontSize: 16,
            color: const Color(0xffF6F9FF),
            height: 1,
          ),
        ],
      ),
    );

    if (!showWithdraw) return balanceBar;

    final withdrawButton = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onWithdraw == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onWithdraw!();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AppText.semiBold(
          "Withdraw",
          fontSize: 12,
          color: AppColors.white,
          height: 1,
          letterSpacing: -0.25,
        ),
      ),
    );

    // Stack width includes the overhang so the full button stays hittable.
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: _withdrawOverhang),
          child: balanceBar,
        ),
        Positioned(right: 0, child: withdrawButton),
      ],
    );
  }
}
