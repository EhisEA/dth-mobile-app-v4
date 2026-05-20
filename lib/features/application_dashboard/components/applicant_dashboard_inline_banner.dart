import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class ApplicantDashboardInlineBanner extends StatelessWidget {
  const ApplicantDashboardInlineBanner({
    super.key,
    required this.banner,
    required this.backgroundColor,
    required this.bodyColor,
    this.svg,
  });

  final ApplicantDashboardBanner banner;
  final Color backgroundColor;
  final Color bodyColor;
  final String? svg;

  @override
  Widget build(BuildContext context) {
    final title = banner.title?.trim() ?? "";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            AppText.semiBold(
              title,
              fontSize: 15,
              color: AppColors.black,
              maxLines: 2,
            ),
          if (title.isNotEmpty && banner.body.trim().isNotEmpty) Gap.h8,
          if (banner.body.trim().isNotEmpty)
            Row(
              children: [
                if (svg != null)
                  SvgPicture.asset(
                    svg!,
                    height: 14,
                    width: 14,
                    colorFilter: ColorFilter.mode(bodyColor, BlendMode.srcIn),
                  ),
                Gap.w8,
                Expanded(
                  child: AppText.regular(
                    banner.body,
                    fontSize: 10,
                    color: bodyColor,
                    maxLines: 6,
                    multiText: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
