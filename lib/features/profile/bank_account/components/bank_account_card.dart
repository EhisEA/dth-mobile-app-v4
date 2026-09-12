import "package:dth_v4/core/constants/assets.dart";
import "package:dth_v4/core/utils/colors.dart";
import "package:dth_v4/data/models/bank_account_model.dart";
import "package:dth_v4/features/profile/bank_account/components/bank_logo_avatar.dart";
import "package:dth_v4/widgets/text/app_text.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/widgets/gap.dart";

class BankAccountCard extends StatelessWidget {
  const BankAccountCard({super.key, required this.account, this.onMoreClicked});

  final BankAccount account;
  final Function()? onMoreClicked;

  /// e.g. "GTBANK" → "GB", "Access Bank" → "AB", "UBA" → "UB".
  static String bankInitials(String bankName) {
    final raw = bankName.trim();
    if (raw.isEmpty) return "?";

    final words = raw
        .split(RegExp(r"[\s\-_]+"))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList(growable: false);

    if (words.length >= 2) {
      final a = words[0][0];
      final b = words[1][0];
      return ("$a$b").toUpperCase();
    }

    final word = words.first.toUpperCase();
    if (word.endsWith("BANK") && word.length > 4) {
      return "${word[0]}B";
    }
    if (word.length >= 2) return word.substring(0, 2);
    return word;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap.w8,
          BankLogoAvatar(
            bankName: account.bankName,
            imageUrl: account.imageUrl,
            size: 40,
            fontSize: 14,
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bold(
                  account.accountNumber,
                  fontSize: 16,
                  color: AppColors.black,
                ),
                AppText.medium(
                  account.bankName,
                  fontSize: 14,
                  maxLines: 1,
                  color: AppColors.tint40,
                ),
                AppText.regular(
                  account.accountName,
                  fontSize: 12,
                  maxLines: 1,
                  color: AppColors.blackTint20,
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMoreClicked,
            child: SvgPicture.asset(SvgAssets.more, width: 36, height: 36),
          ),
        ],
      ),
    );
  }
}
