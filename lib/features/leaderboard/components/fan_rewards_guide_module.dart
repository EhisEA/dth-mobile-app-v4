import "package:dth_v4/data/models/model.dart";

enum FanRewardsGuideModule { howItWorks, weeklyRewards, grandPrize }

FanRewardsGuideModule fanRewardsGuideModuleFor(
  FanLeaderboardGuideTab tab,
  int index,
) {
  final key = tab.key.trim().toLowerCase().replaceAll("_", "-");
  switch (key) {
    case "how-it-works":
    case "howitworks":
      return FanRewardsGuideModule.howItWorks;
    case "weekly-rewards":
    case "weekly":
    case "rewards":
      return FanRewardsGuideModule.weeklyRewards;
    case "grand-prize":
    case "grandprize":
    case "grand":
      return FanRewardsGuideModule.grandPrize;
    default:
      if (index == 1) return FanRewardsGuideModule.weeklyRewards;
      if (index == 2) return FanRewardsGuideModule.grandPrize;
      return FanRewardsGuideModule.howItWorks;
  }
}
