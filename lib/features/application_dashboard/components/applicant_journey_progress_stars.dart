import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application_dashboard/components/applicant_performance_gauge.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Single star + two-tone count label (API `progress.type: stars`).
class ApplicantJourneyProgressStars extends StatelessWidget {
  const ApplicantJourneyProgressStars({super.key, required this.progress});

  final JourneyProgress progress;

  @override
  Widget build(BuildContext context) {
    if (progress.typeNormalized != "stars") return const SizedBox.shrink();
    final starColor = dashboardSemanticColor(progress.color);
    final max = progress.max;
    final value = progress.value;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          SvgAssets.star,
          width: 12,
          height: 12,
          colorFilter: ColorFilter.mode(starColor, BlendMode.srcIn),
        ),
        Gap.w2,
        if (max > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AppText.medium(
                "$value",
                fontSize: 12,
                color: AppColors.mainBlack,
              ),
              AppText.regular(
                "/$max stars",
                fontSize: 10,
                color: AppColors.tint15,
              ),
            ],
          )
        else
          AppText.medium(
            progress.label.trim().isNotEmpty ? progress.label : "—",
            fontSize: 10,
            color: AppColors.mainBlack,
          ),
      ],
    );
  }
}
