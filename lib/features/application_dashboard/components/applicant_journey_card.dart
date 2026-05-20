import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application_dashboard/components/applicant_journey_progress_bar.dart";
import "package:dth_v4/features/application_dashboard/components/applicant_journey_progress_gauge.dart";
import "package:dth_v4/features/application_dashboard/components/applicant_journey_progress_stars.dart";
import "package:dth_v4/features/application_dashboard/components/applicant_performance_gauge.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class ApplicantJourneyCard extends StatelessWidget {
  const ApplicantJourneyCard({
    super.key,
    required this.card,
    required this.width,
    this.onCta,
    this.onCardTap,
    this.scheduleFetchBusy = false,
    this.ctaFetchBusy = false,
  });

  final JourneyCard card;
  final double width;
  final void Function(JourneyCard card)? onCta;

  /// Whole-card tap (e.g. schedule journey opens sheet). Does not replace [onCta].
  final VoidCallback? onCardTap;

  /// Shown while [ApplicantDashboardViewModel.openScheduleSheet] is loading.
  final bool scheduleFetchBusy;

  /// Client-side busy (e.g. prefetching interview slots before opening sheet).
  final bool ctaFetchBusy;

  static Color _chipForeground(JourneyStatusChip chip) {
    final v = (chip.variant ?? chip.tone ?? "").trim().toLowerCase();
    if (v.isEmpty) return AppColors.blackTint20;
    return dashboardSemanticColor(v);
  }

  static Widget _chipLeading(JourneyStatusChip chip, Color color) {
    final raw = chip.icon?.toLowerCase().trim() ?? "";
    if (raw == "dot") {
      return Icon(Icons.circle, size: 7, color: color);
    }
    return SvgPicture.asset(
      chipSvgAsset(chip.icon),
      width: 12,
      height: 12,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Widget? _progressWidget(JourneyProgress? p) {
    if (p == null || !p.isRenderable) return null;
    switch (p.typeNormalized) {
      case "bar":
        return ApplicantJourneyProgressBar(progress: p);
      case "stars":
        return ApplicantJourneyProgressStars(progress: p);
      case "gauge":
        return ApplicantJourneyProgressGauge(progress: p);
      default:
        return null;
    }
  }

  static Color _footerTextColor(JourneyCardFooter footer) {
    final tone = footer.tone?.trim().toLowerCase() ?? "";
    if (tone.isEmpty) return AppColors.tint15;
    return dashboardSemanticColor(tone);
  }

  @override
  Widget build(BuildContext context) {
    final title = card.title?.trim() ?? "";
    final subtitle = card.subtitle?.trim() ?? "";
    final body = card.body?.trim() ?? "";
    final foot = card.footer;
    final chip = card.statusChip;
    final cta = card.cta;
    final progress = _progressWidget(card.progress);

    final Widget inner = Container(
      width: width,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyTint30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            AppText.medium(
              title,
              fontSize: 14,
              color: AppColors.black,
              maxLines: 2,
            ),
          if (title.isNotEmpty && subtitle.isNotEmpty) Gap.h4,
          if (subtitle.isNotEmpty)
            AppText.regular(
              subtitle,
              fontSize: 10,
              color: AppColors.blackTint20,
              maxLines: 2,
              multiText: true,
            ),
          if (body.isNotEmpty && (title.isNotEmpty || subtitle.isNotEmpty))
            Gap.h4,
          if (body.isNotEmpty)
            AppText.regular(
              body,
              fontSize: 10,
              color: AppColors.black,
              maxLines: 4,
              multiText: true,
            ),
          const Spacer(),
          if (progress != null) ...[Gap.h8, progress],
          if (foot != null && !foot.isEmpty) ...[
            InlineTaggedText(foot.label, color: _footerTextColor(foot)),
            Gap.h8,
          ],
          if (cta != null && cta.label.trim().isNotEmpty) ...[
            Gap.h6,
            AppButton.primary(
              text: cta.label,
              width: double.infinity,
              fontSize: 12,
              height: 36,
              radius: 100,
              enabled: cta.enabled && !cta.isLoading && !ctaFetchBusy,
              disableBGColor: AppColors.greyTint20,
              disableTextColor: AppColors.greyTint50,
              isLoading: cta.isLoading || ctaFetchBusy,
              press: cta.enabled && !cta.isLoading && !ctaFetchBusy
                  ? () => onCta?.call(card)
                  : null,
            ),
          ] else if (chip != null && !chip.isEmpty) ...[
            Gap.h6,
            Row(
              children: [
                _chipLeading(chip, _chipForeground(chip)),
                Gap.w4,
                Expanded(
                  child: AppText.regular(
                    chip.label,
                    fontSize: 10,
                    color: _chipForeground(chip),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    Widget wrapped = inner;
    if (scheduleFetchBusy) {
      wrapped = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            wrapped,
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.white.withValues(alpha: 0.55),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (onCardTap != null) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: scheduleFetchBusy ? null : onCardTap,
          child: wrapped,
        ),
      );
    }
    return wrapped;
  }

  static String chipSvgAsset(String? icon) {
    switch (icon?.toLowerCase()) {
      case "schedule":
      case "clock":
        return SvgAssets.clock;
      case "check":
      case "success":
        return SvgAssets.check;
      case "info":
        return SvgAssets.clock;
      default:
        return SvgAssets.rightArrow;
    }
  }
}
