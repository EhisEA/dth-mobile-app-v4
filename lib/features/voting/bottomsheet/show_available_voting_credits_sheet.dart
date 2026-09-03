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
                        AppText.athleticsBold(
                          breakdown.availableLabel,
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                      ],
                    ),
                    Gap.h12,
                    _SegmentedCreditBar(
                      segments: breakdown.segments,
                      total: breakdown.available,
                    ),
                    Gap.h12,
                    ...breakdown.segments.map(
                      (segment) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SegmentLegendRow(segment: segment),
                      ),
                    ),
                    Gap.h16,
                    ...breakdown.sections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CreditSectionCard(section: section),
                      ),
                    ),
                    Gap.h8,
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
                child: Container(color: segment.color),
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
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Gap.w4,
        Expanded(
          child: Text.rich(
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
        ),
      ],
    );
  }
}

class _CreditSectionCard extends StatelessWidget {
  const _CreditSectionCard({required this.section});

  final VotingCreditSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: section.backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            SvgAssets.voteStar,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(section.color, BlendMode.srcIn),
          ),
        ),
        Gap.w16,
        Expanded(
          child: Column(
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
          ),
        ),
      ],
    );
  }
}
