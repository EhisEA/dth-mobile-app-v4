import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/text/app_text.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Rounded card with an illustration, optional dashed rule, title, and subtitle.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    this.showDashedDivider = true,
    this.dashColor = const Color(0xffDAE1F1),
    this.cardDecoration,
    this.cardPadding = const EdgeInsets.all(24),
    this.maxWidth = 360,
    this.outerPadding = const EdgeInsets.symmetric(horizontal: 24),
    this.titleFontSize = 14,
    this.subtitleFontSize = 12,
    this.titleColor = const Color(0xff37406C),
    this.subtitleColor,
    this.titleLetterSpacing = -0.4,
    this.subtitleLetterSpacing = -0.2,
    this.gapAfterIllustration = 8.0,
    this.gapAfterDivider = 24.0,
    this.gapAfterTitle = 8.0,
    this.onRetry,
  });

  final Widget illustration;
  final String title;
  final String subtitle;
  final bool showDashedDivider;
  final Color dashColor;
  final BoxDecoration? cardDecoration;
  final EdgeInsets cardPadding;
  final double maxWidth;
  final EdgeInsets outerPadding;
  final double titleFontSize;
  final double subtitleFontSize;
  final Color titleColor;
  final Color? subtitleColor;
  final double titleLetterSpacing;
  final double subtitleLetterSpacing;
  final double gapAfterIllustration;
  final double gapAfterDivider;
  final double gapAfterTitle;
  final VoidCallback? onRetry;

  static BoxDecoration defaultDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: AppColors.dth100),
      gradient: const LinearGradient(
        colors: [Color(0xFFFAFBFD), Color(0xFFF4F6FA), Color(0xFFFAFBFD)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxOuter = (context.width - outerPadding.horizontal).clamp(
      0,
      maxWidth,
    );
    final subtitleClr = subtitleColor ?? AppColors.dthBlue;

    return Center(
      child: Padding(
        padding: outerPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxOuter.toDouble()),
          child: Container(
            width: double.infinity,
            padding: cardPadding,
            decoration: cardDecoration ?? defaultDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: illustration),
                Gap.h(gapAfterIllustration),
                if (showDashedDivider) ...[
                  SizedBox(
                    height: 1,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _DashedLinePainter(color: dashColor),
                    ),
                  ),
                  Gap.h(gapAfterDivider),
                ],
                AppText.semiBold(
                  title,
                  fontSize: titleFontSize,
                  letterSpacing: titleLetterSpacing,
                  textAlign: TextAlign.center,
                  color: titleColor,
                  multiText: true,
                  centered: true,
                ),
                Gap.h(gapAfterTitle),
                AppText.regular(
                  subtitle,
                  fontSize: subtitleFontSize,
                  letterSpacing: subtitleLetterSpacing,
                  color: subtitleClr,
                  textAlign: TextAlign.center,
                  multiText: true,
                  centered: true,
                ),
                if (onRetry != null) ...[
                  Gap.h16,
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      height: 51,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(48),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xff4D536A),
                            const Color(0xff1C2136),
                          ],
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(48),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xff1F2333),
                              const Color(0xff3E4665),
                            ],
                          ),
                        ),
                        child: AppText.regular(
                          "Retry",
                          color: Colors.white,
                          fontSize: 12,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
                Gap.h32,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 4.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
