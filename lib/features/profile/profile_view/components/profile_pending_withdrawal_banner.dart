import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/text/text.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class ProfilePendingWithdrawalBanner extends StatelessWidget {
  const ProfilePendingWithdrawalBanner({super.key, required this.request});

  final PendingWithdrawalRequest request;

  @override
  Widget build(BuildContext context) {
    final amount = request.formattedLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffFFF3F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(SvgAssets.clock2),
          Gap.w12,
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyle.regular.copyWith(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.black,
                ),
                children: [
                  const TextSpan(text: "Your withdrawal of "),
                  TextSpan(
                    text: amount,
                    style: AppTextStyle.regular.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.black,
                    ),
                  ),
                  const TextSpan(
                    text:
                        " is being processed. We'll notify you when it's complete.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
