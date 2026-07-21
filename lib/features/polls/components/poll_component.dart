import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/polls/components/poll_option_data.dart";
import "package:dth_v4/features/polls/components/poll_option_tile.dart";
import "package:dth_v4/features/voting/components/voting_sponsor_footer.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class PollComponent extends StatefulWidget {
  const PollComponent({
    super.key,
    required this.pollListenable,
    required this.onVoteTap,
    this.isVoteBusy = false,
  });

  final ValueListenable<PollModel?> pollListenable;
  final ValueChanged<String> onVoteTap;
  final bool isVoteBusy;

  @override
  State<PollComponent> createState() => _PollComponentState();
}

class _PollComponentState extends State<PollComponent> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _celebrate(String optionUid) {
    // Safety net for ended polls — `PollOptionTile.enabled` already blocks the
    // tap, but skipping the confetti + vote dispatch here avoids any race
    // (e.g. the poll flips to closed between build and tap).
    final current = widget.pollListenable.value;
    if (current == null || current.isClosed || current.hasVoted) return;

    HapticFeedback.mediumImpact();
    widget.onVoteTap(optionUid);

    _removeOverlay();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => TopConfettiCelebration(onFinished: _removeOverlay),
    );
    _overlayEntry = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PollModel?>(
      valueListenable: widget.pollListenable,
      builder: (context, poll, child) {
        if (poll == null) return const SizedBox.shrink();

        final canVote = !poll.isClosed && !poll.hasVoted && !widget.isVoteBusy;
        final hasVoted = poll.hasVoted;
        final options = poll.options
            .map(
              (option) => PollOptionData(
                uid: option.uid,
                title: option.name,
                percentage: option.percentage,
                progress: (option.percentage / 100).clamp(0.0, 1.0),
                selected: hasVoted && poll.votedOptionUid == option.uid,
                pollHasVoted: hasVoted,
              ),
            )
            .toList();

        final statusText = poll.isClosed ? "Ended" : poll.timeLeft;
        final statusBg = poll.isClosed
            ? AppColors.redTint35.withValues(alpha: 0.08)
            : AppColors.dth100;
        final statusTextColor = poll.isClosed
            ? AppColors.redTint35
            : AppColors.secondaryBlue;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap.h12,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(SvgAssets.primaryLogo, height: 28, width: 28),
                Gap.w8,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.medium(
                        poll.title,
                        fontSize: 14,
                        height: 1,
                        color: AppColors.black,
                      ),
                      Gap.h2,
                      Row(
                        children: [
                          AppText.regular(
                            "Polls",
                            fontSize: 12,
                            height: 0,
                            letterSpacing: -0.25,
                            color: AppColors.blackTint20,
                          ),
                          Gap.w4,
                          AppText.medium(
                            "All Contestants",
                            fontSize: 12,
                            letterSpacing: -0.25,
                            color: AppColors.black,
                          ),
                          Gap.w4,
                          AppText.regular(
                            poll.createdAt,
                            fontSize: 12,
                            letterSpacing: -0.25,
                            color: AppColors.blackTint20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: AppText.medium(
                    statusText,
                    fontSize: 10,
                    color: statusTextColor,
                  ),
                ),
              ],
            ),
            Gap.h8,
            AppText.regular(
              '${poll.question}  ${poll.description}'.trim(),
              fontSize: 13,
              color: AppColors.black,
              multiText: true,
              maxLines: 5,
              letterSpacing: -0.25,
              overflow: TextOverflow.ellipsis,
            ),
            Gap.h8,
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 14,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: Container(
                          height: 14,
                          width: 14,
                          decoration: BoxDecoration(
                            color: hasVoted
                                ? AppColors.dthBlue
                                : const Color(0xffD2D2D2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      hasVoted
                          ? SizedBox(
                              width: 24,
                              height: 16,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    child: Container(
                                      height: 16,
                                      width: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(
                                        SvgAssets.verifyActive,
                                        height: 12,
                                        width: 12,
                                        colorFilter: ColorFilter.mode(
                                          AppColors.dthBlue,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 8,
                                    child: Container(
                                      height: 16,
                                      width: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(
                                        SvgAssets.verifyActive,
                                        height: 12,
                                        width: 12,
                                        colorFilter: ColorFilter.mode(
                                          AppColors.dthBlue,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Positioned(
                              left: 8,
                              child: Container(
                                height: 14,
                                width: 14,
                                decoration: BoxDecoration(
                                  color: hasVoted
                                      ? AppColors.dthBlue
                                      : const Color(0xffD2D2D2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                Gap.w4,
                hasVoted
                    ? AppText.regular(
                        poll.totalVotesDescription,
                        letterSpacing: -0.3,
                        fontSize: 10,
                        color: AppColors.blackTint20,
                      )
                    : AppText.regular(
                        "Select one",
                        fontSize: 10,
                        letterSpacing: -0.3,
                        color: AppColors.blackTint20,
                      ),
              ],
            ),
            Gap.h16,
            for (final option in options) ...[
              PollOptionTile(
                data: option,
                enabled: canVote,
                onTap: () => _celebrate(option.uid),
              ),
              Gap.h16,
            ],
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(ImageAssets.sponsorBg),
                  fit: BoxFit.fill,
                ),
              ),
              child: const VotingSponsorFooter(
                sectionName: "poll",
                includeSafeAreaPadding: false,
                horizontalPadding: 0,
                topPadding: 8,
                backgroundColor: Colors.transparent,
                bottomPadding: 8,
              ),
            ),
            Container(
              height: 1,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xffF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Gap.h16,
          ],
        );
      },
    );
  }
}
