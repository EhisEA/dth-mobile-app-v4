import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";

class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      illustration: Image.asset(
        ImageAssets.notificationsEmptyState,
        width: 157,
        height: 113.99,
      ),
      title: "Nothing New Right Now",
      subtitle:
          "You're all caught up. New notifications about your activity will appear here.",
      showDashedDivider: false,
      cardDecoration: BoxDecoration(),
      cardPadding: EdgeInsets.zero,
      outerPadding: const EdgeInsets.symmetric(horizontal: 44),
      titleFontSize: 14,
      titleColor: AppColors.mainBlack,
      subtitleFontSize: 12,
      subtitleColor: AppColors.paleLavender,
      gapAfterIllustration: 16,
    );
  }
}
