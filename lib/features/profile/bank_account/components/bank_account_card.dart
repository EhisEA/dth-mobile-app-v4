import 'package:dth_v4/core/constants/assets.dart';
import 'package:dth_v4/core/utils/colors.dart';
import 'package:dth_v4/data/models/bank_account_model.dart';
import 'package:dth_v4/widgets/text/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_utils/widgets/gap.dart';

class BankAccountCard extends StatelessWidget {
  const BankAccountCard({super.key, required this.account, this.onMoreClicked});

  final BankAccount account;
  final Function()? onMoreClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onMoreClicked,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: account.url.isNotEmpty
                  ? Image.network(
                      account.url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(Icons.account_balance);
                      },
                    )
                  : const Icon(Icons.account_balance),
            ),
            Gap.w16,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bold(
                  account.accountNumber,
                  fontSize: 16,
                  color: AppColors.mainBlack,
                ),
                AppText.medium(
                  account.bankName,
                  fontSize: 14,
                  color: AppColors.tint40,
                ),
                AppText.regular(
                  account.accountName,
                  fontSize: 12,
                  color: AppColors.blackTint20,
                ),
              ],
            ),
            const Spacer(),
            SvgPicture.asset(SvgAssets.more, width: 36, height: 36),
          ],
        ),
      ),
    );
  }
}
