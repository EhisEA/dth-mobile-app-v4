import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/guide_item_icon.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class GuideHowItWorksModule extends StatelessWidget {
  const GuideHowItWorksModule({super.key, required this.tab});

  final FanLeaderboardGuideTab tab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tab.body.isNotEmpty) ...[
          Gap.h24,
          ...tab.body.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppText.regular(
                line,
                fontSize: 16,
                height: 1.3,
                letterSpacing: -0.1,
                color: AppColors.white,
                multiText: true,
              ),
            ),
          ),
        ],
        if (tab.items.isNotEmpty) ...[
          Gap.h24,
          AppText.shantellBold(
            "How it works:",
            fontSize: 16,
            letterSpacing: -0.6,
            color: AppColors.white,
          ),
          Gap.h12,
          ...tab.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GuideItemIcon(icon: item.icon, size: 16),
                  ),
                  Gap.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.medium(
                          item.heading,
                          fontSize: 16,
                          color: const Color(0xffC2FFE0),
                        ),
                        if (item.text.trim().isNotEmpty) ...[
                          Gap.h4,
                          AppText.regular(
                            item.text,
                            fontSize: 14,
                            height: 1.2,
                            letterSpacing: -0.25,
                            color: AppColors.scaffold,
                            multiText: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
