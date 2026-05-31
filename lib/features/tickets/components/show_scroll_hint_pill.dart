import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";

/// Floating hint to scroll when more content (e.g. purchased tickets) is below the fold.
class ShowScrollHintPill extends StatelessWidget {
  const ShowScrollHintPill({super.key, this.onTap});

  final VoidCallback? onTap;

  static const _pillRadius = 100.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_pillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: Color(0xffFCFCFC),
            borderRadius: BorderRadius.circular(_pillRadius),
            boxShadow: [
              BoxShadow(
                color: Color(0xff354A68).withValues(alpha: 0.12),
                blurRadius: 32,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "Continue reading",
                  style: AppTextStyle.regular.copyWith(
                    fontSize: 12,
                    color: AppColors.primary,
                    letterSpacing: -0.2,
                  ),
                ),
                WidgetSpan(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: SvgPicture.asset(
                      SvgAssets.downArrow,
                      height: 12,
                      width: 12,
                      colorFilter: ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
