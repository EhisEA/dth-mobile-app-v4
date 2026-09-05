import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class GuideTabBar extends StatelessWidget {
  const GuideTabBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.activeColor,
    required this.onTap,
  });

  final List<FanLeaderboardGuideTab> tabs;
  final int activeIndex;
  final Color activeColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) Gap.w8,
            GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: i == activeIndex
                      ? activeColor
                      : const Color(0XFF151515),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: AppText.medium(
                  "${tabs[i].position}. ${tabs[i].tabLabel}",
                  fontSize: 12,
                  color: i == activeIndex
                      ? AppColors.scaffold
                      : AppColors.blackTint20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
