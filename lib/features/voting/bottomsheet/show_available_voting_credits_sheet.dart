import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/voting/bottomsheet/show_top_up_voting_credits_sheet.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:intl/intl.dart";

Future<void> showAvailableVotingCreditsSheet(
  BuildContext context, {
  required VotingCreditBreakdown breakdown,
}) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    builder: (sheetContext) =>
        _AvailableVotingCreditsSheetBody(initialBreakdown: breakdown),
  );
}

class _AvailableVotingCreditsSheetBody extends ConsumerWidget {
  const _AvailableVotingCreditsSheetBody({required this.initialBreakdown});

  final VotingCreditBreakdown initialBreakdown;

  static final _numberFormat = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userStateProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ValueListenableBuilder<UserModel?>(
      valueListenable: userState.user,
      builder: (context, user, _) {
        final breakdown = user?.votingCreditBreakdown ?? initialBreakdown;
        final available = user?.votingCredit ?? breakdown.available;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffEEFCF5),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: AppText.medium(
                          "Available Credits",
                          fontSize: 12,
                          color: VotingCreditPalette.subscription,
                        ),
                      ),
                    ),
                    Gap.h8,
                    Center(
                      child: AppText.athleticsExtraBold(
                        _numberFormat.format(available),
                        fontSize: 50,
                        height: 1.1,
                        letterSpacing: -0.2,
                        color: AppColors.mainBlack,
                      ),
                    ),
                    Gap.h24,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.semiBold(
                          breakdown.title,
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                        Text.rich(
                          TextSpan(
                            style: AppTextStyle.athleticsRegular.copyWith(
                              fontSize: 12,
                              height: 1,
                              letterSpacing: -0.3,
                              color: AppColors.black,
                            ),
                            children: [
                              TextSpan(
                                text: _numberFormat.format(available),
                                style: AppTextStyle.athleticsBold.copyWith(
                                  fontSize: 12,
                                  height: 1,
                                  letterSpacing: -0.3,
                                  color: AppColors.black,
                                ),
                              ),
                              const TextSpan(text: " available"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Gap.h12,
                    _SegmentedCreditBar(
                      segments: breakdown.segments,
                      total: breakdown.available,
                    ),
                    Gap.h12,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < breakdown.segments.length; i++) ...[
                          if (i > 0) Gap.w16,
                          _SegmentLegendRow(segment: breakdown.segments[i]),
                        ],
                      ],
                    ),
                    Gap.h24,
                    _CreditSectionsBlock(sections: breakdown.sections),
                    Gap.h32,
                    AppButton.primary(
                      text: "Top up credit",
                      height: 55,
                      fontSize: 16,
                      press: () => unawaited(_openTopUp(context)),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.greyTint15,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.greyTint55,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTopUp(BuildContext context) async {
    await showTopUpVotingCreditsSheet(context);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _SegmentedCreditBar extends StatelessWidget {
  const _SegmentedCreditBar({required this.segments, required this.total});

  final List<VotingCreditSegment> segments;
  final int total;

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.amount > 0).toList(growable: false);
    if (visible.isEmpty || total <= 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.greyTint25,
          borderRadius: BorderRadius.circular(100),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            for (final segment in visible)
              Expanded(
                flex: segment.amount,
                child: _SegmentFill(
                  color: segment.color,
                  gradient: segment.gradient,
                  insetShadowColor: segment.insetShadowColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Solid/gradient fill with Figma-style inner shadow (y: 4, blur: 7).
class _SegmentFill extends StatelessWidget {
  const _SegmentFill({
    required this.color,
    required this.insetShadowColor,
    this.gradient,
    this.width,
    this.height,
    this.borderRadius,
  });

  final Color color;
  final Color insetShadowColor;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null ? color : null,
              ),
            ),
            // Inner shadow: offset (0, 4), blur 7 — soft inset glow from the top.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(0, -1.2),
                    end: const Alignment(0, 0.6),
                    colors: [
                      insetShadowColor.withValues(alpha: 0.7),
                      insetShadowColor.withValues(alpha: 0.2),
                      insetShadowColor.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentLegendRow extends StatelessWidget {
  const _SegmentLegendRow({required this.segment});

  final VotingCreditSegment segment;

  static final _numberFormat = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SegmentFill(
          width: 8,
          height: 8,
          borderRadius: BorderRadius.circular(2),
          color: segment.color,
          gradient: segment.gradient,
          insetShadowColor: segment.insetShadowColor,
        ),
        Gap.w4,
        Text.rich(
          TextSpan(
            style: AppTextStyle.regular.copyWith(
              fontSize: 10,
              color: AppColors.black,
              letterSpacing: -0.25,
            ),
            children: [
              TextSpan(text: "${segment.label}: "),
              TextSpan(
                text: _numberFormat.format(segment.amount),
                style: AppTextStyle.athleticsBlack.copyWith(
                  fontSize: 10,
                  color: AppColors.mainBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreditSectionsBlock extends StatelessWidget {
  const _CreditSectionsBlock({required this.sections});

  final List<VotingCreditSection> sections;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) Gap.h16,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sections[i].backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  SvgAssets.voteStar,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    sections[i].color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Gap.w16,
              Expanded(child: _CreditSectionText(section: sections[i])),
            ],
          ),
        ],
      ],
    );
  }
}

class _CreditSectionText extends StatelessWidget {
  const _CreditSectionText({required this.section});

  final VotingCreditSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.medium(
          section.title,
          fontSize: 14,
          color: AppColors.black,
          multiText: true,
        ),
        Gap.h4,
        AppText.regular(
          section.description,
          fontSize: 12,
          height: 1.4,
          letterSpacing: -0.25,
          color: AppColors.tint25,
          multiText: true,
        ),
      ],
    );
  }
}
