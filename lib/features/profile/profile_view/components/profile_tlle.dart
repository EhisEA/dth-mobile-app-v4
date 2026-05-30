import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class ProfileTlle extends StatelessWidget {
  const ProfileTlle({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    required this.icon,
    this.isRed = false,
    this.showRightArrow = true,
    this.widget,
  });
  final String title;
  final String description;
  final VoidCallback onTap;
  final String icon;
  final bool isRed;
  final bool showRightArrow;
  final Widget? widget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: isRed ? AppColors.redTint35 : AppColors.dthBlue,
            child: SvgPicture.asset(icon),
          ),
          Gap.w14,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.regular(title, fontSize: 14, color: AppColors.black),
                Gap.h2,
                AppText.regular(
                  description,
                  fontSize: 12,
                  color: AppColors.tint15,
                ),
              ],
            ),
          ),

          if (showRightArrow) SvgPicture.asset(SvgAssets.rightArrow),
          if (widget != null) widget!,
        ],
      ),
    );
  }
}
