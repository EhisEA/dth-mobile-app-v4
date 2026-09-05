import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/fan_rewards_guide_module.dart";
import "package:dth_v4/features/leaderboard/components/guide_grand_prize_module.dart";
import "package:dth_v4/features/leaderboard/components/guide_how_it_works_module.dart";
import "package:dth_v4/features/leaderboard/components/guide_weekly_rewards_module.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class GuideTabContent extends StatelessWidget {
  const GuideTabContent({
    super.key,
    required this.tab,
    required this.module,
    required this.calloutBg,
  });

  final FanLeaderboardGuideTab tab;
  final FanRewardsGuideModule module;
  final Color calloutBg;

  @override
  Widget build(BuildContext context) {
    // Grand prize API puts the short tagline in `body` and the long copy in
    // `subtitle`; other tabs use subtitle as the short line.
    final shortLine = module == FanRewardsGuideModule.grandPrize
        ? (tab.body.isNotEmpty ? tab.body.first : "")
        : tab.subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.semiBold(
          tab.title,
          fontSize: 32,
          height: 1.1,
          color: AppColors.white,
          multiText: true,
        ),
        if (shortLine.trim().isNotEmpty) ...[
          Gap.h24,
          AppText.shantellBold(
            shortLine,
            fontSize: 16,
            height: 1.35,
            letterSpacing: -0.6,
            color: AppColors.white,
            multiText: true,
          ),
        ],
        switch (module) {
          FanRewardsGuideModule.howItWorks => GuideHowItWorksModule(tab: tab),
          FanRewardsGuideModule.weeklyRewards => GuideWeeklyRewardsModule(
            tab: tab,
            calloutBg: calloutBg,
          ),
          FanRewardsGuideModule.grandPrize => GuideGrandPrizeModule(tab: tab),
        },
      ],
    );
  }
}
