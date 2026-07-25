import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/models/voting_credits.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class VotingHeader extends StatelessWidget {
  const VotingHeader({super.key, required this.credits, this.onTap});

  final VotingCredits credits;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AppText.medium(
            "Voting",
            fontSize: 24,
            color: AppColors.tertiary60,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xffE5FBF0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(SvgAssets.voteStar),
              Gap.w6,
              AppText.semiBold(
                credits.label,
                fontSize: 12,
                color: const Color(0xff00AD55),
              ),
            ],
          ),
        ),
        Gap.w4,
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          child: CircleAvatar(
            radius: 16.5,
            backgroundColor: AppColors.dth100,
            child: Center(child: SvgPicture.asset(SvgAssets.question)),
          ),
        ),
      ],
    );
  }
}
