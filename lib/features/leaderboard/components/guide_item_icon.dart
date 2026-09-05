import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

/// Renders the guide item icon from [FanLeaderboardGuideIcon].
class GuideItemIcon extends StatelessWidget {
  const GuideItemIcon({
    super.key,
    required this.icon,
    this.size = 16,
    this.color = const Color(0xffFFCE22),
  });

  final FanLeaderboardGuideIcon icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (icon) {
      case FanLeaderboardGuideIcon.spark:
        return SvgPicture.asset(
          SvgAssets.voteStar,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      case FanLeaderboardGuideIcon.medalGold:
        return SvgPicture.asset(SvgAssets.medalGold, width: size, height: size);
      case FanLeaderboardGuideIcon.medalSilver:
        return SvgPicture.asset(
          SvgAssets.medalSilver,
          width: size,
          height: size,
        );
      case FanLeaderboardGuideIcon.medalBronze:
        return SvgPicture.asset(
          SvgAssets.medalBronze,
          width: size,
          height: size,
        );
      case FanLeaderboardGuideIcon.check:
        return SvgPicture.asset(
          SvgAssets.doubleTick,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
    }
  }
}
