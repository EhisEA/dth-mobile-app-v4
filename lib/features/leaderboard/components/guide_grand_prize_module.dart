import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/guide_item_icon.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class GuideGrandPrizeModule extends StatelessWidget {
  const GuideGrandPrizeModule({super.key, required this.tab});

  final FanLeaderboardGuideTab tab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tab.subtitle.trim().isNotEmpty) ...[
          Gap.h16,
          AppText.regular(
            tab.subtitle,
            fontSize: 16,
            height: 1.45,
            color: AppColors.white,
            multiText: true,
          ),
        ],
        if (tab.items.isNotEmpty) ...[
          Gap.h24,
          AppText.shantellBold(
            "Grand prize includes:",
            fontSize: 16,
            letterSpacing: -0.6,
            color: AppColors.white,
          ),
          Gap.h12,
          ...tab.items.map((item) {
            final label = item.heading.trim().isNotEmpty
                ? item.heading
                : item.text;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GuideItemIcon(icon: item.icon, size: 12),
                  ),
                  Gap.w16,
                  Expanded(
                    child: AppText.regular(
                      label,
                      fontSize: 16,
                      height: 1.4,
                      color: AppColors.scaffold,
                      multiText: true,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
