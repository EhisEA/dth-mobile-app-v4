import "dart:math" as math;

import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Semicircular performance gauge: **radial tick marks** along the upper arc
/// (light gray empty track; filled portion uses [arcColor] from the left).
class ApplicantPerformanceGauge extends StatelessWidget {
  const ApplicantPerformanceGauge({
    super.key,
    required this.score,
    required this.max,
    required this.arcColor,
    required this.label,
    required this.caption,
  });

  final int score;
  final int max;
  final Color arcColor;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final pct = max <= 0 ? 0 : ((score / max) * 100).round().clamp(0, 100);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 120,
          child: CustomPaint(
            painter: ApplicantRadialTickGaugePainter(
              progress: pct / 100.0,
              arcColor: arcColor,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 38),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.black(
                    "$pct%",
                    fontSize: 44,
                    color: AppColors.black,
                    height: 1.1,
                  ),
                  AppText.bold(
                    "of $max",
                    fontSize: 16,
                    color: AppColors.tint15,
                    height: 1.2,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Gap.h16,
        AppText.semiBold(
          label,
          fontSize: 14,
          color: AppColors.black,
          textAlign: TextAlign.center,
          centered: true,
        ),
        Gap.h6,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              SvgAssets.infoOutline,
              width: 12,
              height: 12,
              colorFilter: ColorFilter.mode(AppColors.tint15, BlendMode.srcIn),
            ),
            Gap.w4,
            Flexible(
              child: AppText.regular(
                caption,
                fontSize: 11,
                color: AppColors.tint15,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Radial tick semicircle (segmented speedometer look); shared by dashboard and journey-card gauges.
class ApplicantRadialTickGaugePainter extends CustomPainter {
  ApplicantRadialTickGaugePainter({
    required this.progress,
    required this.arcColor,
  });

  final double progress;
  final Color arcColor;

  /// Upper semicircle: π (left) → 2π (right), passing through the top.
  static const double _start = math.pi;
  static const double _sweep = math.pi;

  static const int _tickCount = 64;
  static const double _tickStrokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = w * 0.40;
    final center = Offset(w / 2, h * 0.78);
    final tickLength = radius * 0.12;

    // Wide white arc behind ticks so the gauge reads on tinted page backgrounds.
    final trackMidRadius = radius - tickLength * 0.30;
    final whiteTrack = Paint()
      ..color = AppColors.white.withValues(alpha: 0.54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tickLength * 1.50
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: trackMidRadius),
      _start,
      _sweep,
      false,
      whiteTrack,
    );

    final trackColor = AppColors.greyTint30;
    final p = progress.clamp(0.0, 1.0);

    for (var i = 0; i < _tickCount; i++) {
      final t = i / (_tickCount - 1);
      final theta = _start + t * _sweep;
      final dir = Offset(math.cos(theta), math.sin(theta));
      final outer = center + dir * radius;
      final inner = center + dir * (radius - tickLength);

      final filled = p > 0 && t <= p;
      final color = filled ? arcColor : trackColor;

      final paint = Paint()
        ..color = color
        ..strokeWidth = _tickStrokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ApplicantRadialTickGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.arcColor != arcColor;
  }
}

/// Maps API semantic strings (`green`, `amber`, `success`, `danger`, …) to UI colors
/// for journey progress, status chips, and the performance gauge arc.
Color dashboardSemanticColor(String key) {
  switch (key.trim().toLowerCase()) {
    case "success":
    case "green":
      return AppColors.primary;
    case "danger":
    case "red":
      return AppColors.redTint35;
    case "neutral":
    case "grey":
    case "gray":
    case "muted":
      return AppColors.greyTint55;
    case "amber":
    case "orange":
    case "warning":
      return AppColors.secondaryOrange;
    case "blue":
      return AppColors.secondaryBlue;
    default:
      return AppColors.black;
  }
}

Color applicantPerformanceArcColor(String colorKey) {
  return dashboardSemanticColor(colorKey);
}
