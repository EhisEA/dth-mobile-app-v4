import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Profile top-right wallet balance pill (same shell as voting credits).
class ProfileWalletBalancePill extends StatelessWidget {
  const ProfileWalletBalancePill({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final balance = user.walletBalance ?? const WalletBalance();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffFCFCFC),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          AppText.shantellMedium(
            balance.currencySymbol,
            fontSize: 16,
            color: AppColors.mainBlack,
            height: 1,
          ),
          Gap.w(2),
          AppText.shantellBold(
            balance.amount,
            fontSize: 18,
            color: AppColors.primary,
            height: 1,
          ),
        ],
      ),
    );
  }
}
