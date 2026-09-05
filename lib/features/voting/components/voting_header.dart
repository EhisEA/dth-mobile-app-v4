import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/components/voting_credits_chip.dart";
import "package:dth_v4/features/voting/models/voting_credits.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class VotingHeader extends StatelessWidget {
  const VotingHeader({
    super.key,
    required this.credits,
    this.onTap,
    this.onCreditsTap,
    this.onAddCreditsTap,
  });

  final VotingCredits credits;
  final VoidCallback? onTap;
  final VoidCallback? onCreditsTap;
  final VoidCallback? onAddCreditsTap;

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
        VotingCreditsChip(
          label: credits.remainingLabel,
          showAddIcon: true,
          onTap: onCreditsTap,
          onAddTap: onAddCreditsTap ?? onCreditsTap,
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
