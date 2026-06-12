import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";

/// Stacked verify badge + overlapping **PRO** pill for the subscription tab.
class ProBadgeIcon extends StatelessWidget {
  const ProBadgeIcon({super.key, this.size = 24, required this.isActive});

  final double size;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scale = size / 24;
    final pillHPad = 5.0 * scale;
    final pillVPad = 4.0 * scale;
    final fontSize = 6 * scale;
    final borderWidth = 2.0 * scale;
    final pillRight = -7.0 * scale;
    final pillTop = -4.0 * scale;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset(
            isActive ? SvgAssets.verifyActive : SvgAssets.verify,
            width: size,
            height: size,
          ),
          Positioned(
            right: pillRight,
            top: pillTop,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isActive ? AppColors.redTint35 : AppColors.dthBlue,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.white, width: borderWidth),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: pillHPad,
                  vertical: pillVPad,
                ),
                child: Text(
                  "PRO",
                  style: AppTextStyle.semiBold.copyWith(
                    fontSize: fontSize,
                    height: 1,
                    letterSpacing: -0.1,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
