import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application_dashboard/components/applicant_performance_gauge.dart";
import "package:dth_v4/widgets/text/text.dart";
import "package:flutter/material.dart";

/// Compact semicircular gauge for journey cards (`progress.type` == `gauge`).
class ApplicantJourneyProgressGauge extends StatelessWidget {
  const ApplicantJourneyProgressGauge({super.key, required this.progress});

  final JourneyProgress progress;

  @override
  Widget build(BuildContext context) {
    final maxRaw = progress.max;
    final score = maxRaw > 0 ? progress.value.clamp(0, maxRaw) : 0;
    final frac = maxRaw <= 0 ? 0.0 : (score / maxRaw).clamp(0.0, 1.0);
    final arcColor = applicantPerformanceArcColor(progress.color);
    final labelRaw = progress.label.trim();
    final pctRounded = (frac * 100).round().clamp(0, 100);
    final displayLabel = labelRaw.isNotEmpty
        ? labelRaw
        : "$pctRounded% of $maxRaw";

    return SizedBox(
      height: 62,
      width: double.infinity,
      child: CustomPaint(
        painter: ApplicantRadialTickGaugePainter(
          progress: frac,
          arcColor: arcColor,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.topCenter,
            child: _JourneyGaugeLabel(text: displayLabel),
          ),
        ),
      ),
    );
  }
}

class _JourneyGaugeLabel extends StatelessWidget {
  const _JourneyGaugeLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final m = RegExp(
      r"^(\d+)\s*%\s*(of\s+.+)$",
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (m == null) {
      return Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.semiBold.copyWith(
          fontSize: 14,
          color: AppColors.mainBlack,
          height: 1.2,
        ),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "${m.group(1)}%",
            style: AppTextStyle.bold.copyWith(
              fontSize: 20,
              color: AppColors.mainBlack,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: " ${m.group(2)}",
            style: AppTextStyle.regular.copyWith(
              fontSize: 12,
              color: AppColors.tint15,
              height: 1.2,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
