import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/components/voting_sponsor_footer.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:intl/intl.dart";

Future<void> showVoteSuccessSheet(
  BuildContext context, {
  required int voteCount,
  required String contestantName,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => TopConfettiCelebration(
      onFinished: () {
        entry.remove();
      },
    ),
  );
  overlay.insert(entry);

  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    builder: (sheetContext) => _VoteSuccessSheetBody(
      voteCount: voteCount,
      contestantName: contestantName,
    ),
  );
}

class _VoteSuccessSheetBody extends StatelessWidget {
  const _VoteSuccessSheetBody({
    required this.voteCount,
    required this.contestantName,
  });

  final int voteCount;
  final String contestantName;

  @override
  Widget build(BuildContext context) {
    final formattedVotes = NumberFormat.decimalPattern().format(voteCount);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(ImageAssets.confirmed, height: 110),
                    ),
                    Gap.h20,
                    Center(
                      child: _VotingPointsUsedBadge(voteCount: formattedVotes),
                    ),
                    Gap.h16,
                    AppText.semiBold(
                      "Thanks for Voting!",
                      fontSize: 20,
                      color: AppColors.mainBlack,
                      textAlign: TextAlign.center,
                      height: 1,
                    ),
                    Gap.h10,
                    Text.rich(
                      TextSpan(
                        style: AppTextStyle.regular.copyWith(
                          fontSize: 16,
                          height: 1.2,
                          color: AppColors.black,
                          letterSpacing: -0.2,
                        ),
                        children: [
                          const TextSpan(
                            text: "Your support means a lot. Your votes for ",
                          ),
                          TextSpan(
                            text: contestantName,
                            style: AppTextStyle.semiBold.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          const TextSpan(text: " have been counted."),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gap.h24,
                    AppButton.onBorder(
                      text: "Alright. Got it.",
                      fontSize: 16,
                      press: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 15,
                right: 10,
                child: Material(
                  color: const Color(0xffF7F7F7),
                  shape: const CircleBorder(),
                  elevation: 1,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).maybePop();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xff505050),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const VotingSponsorFooter(),
        ],
      ),
    );
  }
}

class _VotingPointsUsedBadge extends StatelessWidget {
  const _VotingPointsUsedBadge({required this.voteCount});

  final String voteCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: const Color(0xffF1F3FE),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryBlue,
                borderRadius: BorderRadius.circular(500),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    SvgAssets.voteStar,
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  Gap.w4,
                  AppText.black(
                    voteCount,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AppText.semiBold(
                "VOTING POINTS USED",
                fontSize: 11,
                color: AppColors.secondaryBlue,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
