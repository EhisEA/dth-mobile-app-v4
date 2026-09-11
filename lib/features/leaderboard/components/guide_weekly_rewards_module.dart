import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/guide_item_icon.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class GuideWeeklyRewardsModule extends StatelessWidget {
  const GuideWeeklyRewardsModule({
    super.key,
    required this.tab,
    required this.calloutBg,
  });

  final FanLeaderboardGuideTab tab;
  final Color calloutBg;

  @override
  Widget build(BuildContext context) {
    final footnotes = <String>[];
    final callouts = <String>[];
    for (final line in tab.body) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith("*")) {
        footnotes.add(trimmed);
        continue;
      }
      // API may send footnote + callout in one sentence.
      final splitAt = trimmed.indexOf(". ");
      if (splitAt > 0 && splitAt < trimmed.length - 2) {
        footnotes.add("* ${trimmed.substring(0, splitAt)}");
        callouts.add(trimmed.substring(splitAt + 2).trim());
      } else {
        callouts.add(trimmed);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tab.items.isNotEmpty) ...[
          Gap.h28,
          ...tab.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.heading.trim().isNotEmpty)
                          AppText.semiBold(
                            item.heading.toUpperCase(),
                            fontSize: 9,
                            letterSpacing: 0.6,
                            color: const Color(0xffC2FFE0),
                          ),
                        if (item.text.trim().isNotEmpty) ...[
                          Gap.h4,
                          AppText.bold(
                            item.text,
                            fontSize: 24,
                            height: 1.1,
                            color: AppColors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                  GuideItemIcon(icon: item.icon, size: 64),
                  Gap.w8,
                ],
              ),
            );
          }),
        ],
        if (footnotes.isNotEmpty) ...[
          Gap.h8,
          ...footnotes.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppText.regular(
                line,
                fontSize: 12,
                color: AppColors.white,
                multiText: true,
              ),
            ),
          ),
        ],
        if (callouts.isNotEmpty) ...[
          Gap.h16,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: calloutBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const GuideItemIcon(
                  icon: FanLeaderboardGuideIcon.reward,
                  size: 32,
                ),
                Gap.w12,
                Expanded(
                  child: AppText.regular(
                    callouts.join("\n"),
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.white.withValues(alpha: 0.9),
                    multiText: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
