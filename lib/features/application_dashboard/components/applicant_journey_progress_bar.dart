import "dart:math" as math;

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application_dashboard/components/applicant_performance_gauge.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Discrete vertical segments + white gaps (API `progress.type: bar`).
/// No outer track border — unfilled area is transparent (card background).
class ApplicantJourneyProgressBar extends StatelessWidget {
  const ApplicantJourneyProgressBar({super.key, required this.progress});

  final JourneyProgress progress;

  static const double _barHeight = 6;

  /// Target geometry for slot count; actual segment width is stretched so slots
  /// span the full width (Figma: many thin vertical strokes + narrow white gaps).
  static const double _segmentWidthTarget = 2;
  static const double _gap = 1.5;

  @override
  Widget build(BuildContext context) {
    if (progress.typeNormalized != "bar") return const SizedBox.shrink();
    final max = progress.max;
    final frac = max <= 0 ? 0.0 : (progress.value / max).clamp(0.0, 1.0);
    final fillColor = dashboardSemanticColor(progress.color);
    final label = progress.label.trim().isNotEmpty
        ? progress.label
        : "${(frac * 100).round()}%";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              return SizedBox(
                height: _barHeight,
                width: c.maxWidth,
                child: CustomPaint(
                  painter: _DiscreteSegmentBarPainter(
                    width: c.maxWidth,
                    height: _barHeight,
                    fraction: frac,
                    fillColor: fillColor,
                    segmentWidthTarget: _segmentWidthTarget,
                    gap: _gap,
                  ),
                ),
              );
            },
          ),
        ),
        Gap.w8,
        AppText.regular(
          label,
          fontSize: 10,
          color: AppColors.mainBlack,
          letterSpacing: 0.2,
        ),
      ],
    );
  }
}

/// Filled portion = first [fraction] of segment slots. Vertical rects with
/// fixed [gap] (card white); outer silhouette is a stadium clip like Figma.
class _DiscreteSegmentBarPainter extends CustomPainter {
  _DiscreteSegmentBarPainter({
    required this.width,
    required this.height,
    required this.fraction,
    required this.fillColor,
    required this.segmentWidthTarget,
    required this.gap,
  });

  final double width;
  final double height;
  final double fraction;
  final Color fillColor;
  final double segmentWidthTarget;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final unit = segmentWidthTarget + gap;
    if (unit <= 0) return;

    final maxSlots = math.max(1, ((w + gap) / unit).floor());
    final totalGapWidth = (maxSlots - 1) * gap;
    final segW = (w - totalGapWidth) / maxSlots;
    if (segW <= 0) return;

    final filledSlots = (maxSlots * fraction.clamp(0.0, 1.0)).round().clamp(
      0,
      maxSlots,
    );
    if (filledSlots == 0) return;

    final paint = Paint()..color = fillColor;
    final clipRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(h * 0.5),
    );

    canvas.save();
    canvas.clipRRect(clipRRect);

    for (var i = 0; i < filledSlots; i++) {
      final left = i * (segW + gap);
      if (left >= w) break;
      final drawW = math.min(segW, w - left);
      if (drawW <= 0) break;
      canvas.drawRect(Rect.fromLTWH(left, 0, drawW, h), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiscreteSegmentBarPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.fraction != fraction ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.segmentWidthTarget != segmentWidthTarget ||
        oldDelegate.gap != gap;
  }
}
