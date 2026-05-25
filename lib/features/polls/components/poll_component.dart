import "dart:math" as math;

import "package:confetti/confetti.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/polls/components/poll_option_data.dart";
import "package:dth_v4/features/polls/components/poll_option_tile.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:intl/intl.dart";

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
  static const Duration _confettiDuration = Duration(milliseconds: 2200);
  static const Duration _confettiCleanup = Duration(milliseconds: 5500);

  static const List<Color> _confettiColors = [
    Color(0xFF00AD55), // primary green
    Color(0xFF284FEB), // secondary blue
    Color(0xFFF2A257), // secondary orange
    Color(0xFFFE5349), // red tint
    Color(0xFFFFD700), // celebratory gold
    Color(0xFFE94B92), // pink pop
    Color(0xFF7C4DFF), // violet pop
  ];

  static const Size _confettiMinSize = Size(8, 4);
  static const Size _confettiMaxSize = Size(18, 10);

  late final ConfettiController _centerController;
  late final ConfettiController _leftController;
  late final ConfettiController _rightController;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _centerController = ConfettiController(duration: _confettiDuration);
    _leftController = ConfettiController(duration: _confettiDuration);
    _rightController = ConfettiController(duration: _confettiDuration);
  }

  @override
  void dispose() {
    _removeOverlay();
    _centerController.dispose();
    _leftController.dispose();
    _rightController.dispose();
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
      builder: (_) => IgnorePointer(
        child: Stack(
          children: [
            // Big center burst — radiates outward, fills the screen
            Align(
              alignment: const Alignment(0, -0.7),
              child: ConfettiWidget(
                confettiController: _centerController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.08,
                numberOfParticles: 45,
                minBlastForce: 25,
                maxBlastForce: 55,
                gravity: 0.35,
                particleDrag: 0.04,
                shouldLoop: false,
                colors: _confettiColors,
                minimumSize: _confettiMinSize,
                maximumSize: _confettiMaxSize,
              ),
            ),
            // Left shower — wide cone aimed down-right
            Align(
              alignment: const Alignment(-0.9, -0.95),
              child: ConfettiWidget(
                confettiController: _leftController,
                blastDirection: math.pi / 3, // 60° (down + slightly right)
                blastDirectionality: BlastDirectionality.directional,
                emissionFrequency: 0.1,
                numberOfParticles: 30,
                minBlastForce: 30,
                maxBlastForce: 55,
                gravity: 0.35,
                particleDrag: 0.04,
                shouldLoop: false,
                colors: _confettiColors,
                minimumSize: _confettiMinSize,
                maximumSize: _confettiMaxSize,
              ),
            ),
            // Right shower — wide cone aimed down-left
            Align(
              alignment: const Alignment(0.9, -0.95),
              child: ConfettiWidget(
                confettiController: _rightController,
                blastDirection: 2 * math.pi / 3, // 120° (down + slightly left)
                blastDirectionality: BlastDirectionality.directional,
                emissionFrequency: 0.1,
                numberOfParticles: 30,
                minBlastForce: 30,
                maxBlastForce: 55,
                gravity: 0.35,
                particleDrag: 0.04,
                shouldLoop: false,
                colors: _confettiColors,
                minimumSize: _confettiMinSize,
                maximumSize: _confettiMaxSize,
              ),
            ),
          ],
        ),
      ),
    );
    _overlayEntry = entry;
    overlay.insert(entry);

    _centerController.play();
    _leftController.play();
    _rightController.play();

    Future.delayed(_confettiCleanup, _removeOverlay);
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.medium(
                            poll.title,
                            fontSize: 14,
                            height: 0,
                            color: AppColors.black,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SvgPicture.asset(
                            SvgAssets.blackLogo,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              AppColors.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                          Gap.w4,
                          AppText.regular(
                            "with",
                            fontSize: 10,
                            height: 0,

                            color: AppColors.blackTint20,
                          ),
                          Gap.w4,
                          AppText.medium(
                            "All Contestants",
                            fontSize: 10,
                            height: 0,
                            color: AppColors.black,
                          ),
                        ],
                      ),
                      AppText.medium(
                        poll.endsAt,
                        fontSize: 12,
                        color: AppColors.black,
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
            AppText.regular(
              '${poll.question} ${poll.description}'.trim(),
              fontSize: 12,
              color: AppColors.black,
              multiText: true,
              maxLines: 5,
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
                            color: const Color(0xffD2D2D2),
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
                      Positioned(
                        left: 8,
                        child: Container(
                          height: 14,
                          width: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xffD2D2D2),
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
                AppText.regular(
                  poll.hasVoted ? "Vote submitted" : "Select one",
                  fontSize: 10,
                  color: AppColors.blackTint20,
                ),
                const Spacer(),
                SvgPicture.asset(
                  SvgAssets.verifyActive,
                  height: 12,
                  width: 12,
                  colorFilter: ColorFilter.mode(
                    AppColors.tint10,
                    BlendMode.srcIn,
                  ),
                ),
                Gap.w2,
                AppText.regular(
                  "${NumberFormat.decimalPattern().format(poll.totalVotes)} total points",
                  fontSize: 10,
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
            Row(
              children: [
                SizedBox(
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
                ),
                Gap.w4,
                AppText.regular(
                  poll.totalVotesDescription,
                  fontSize: 10,
                  color: AppColors.blackTint20,
                  letterSpacing: -0.3,
                ),
              ],
            ),
            Gap.h8,
            Container(
              height: 1,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xffF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        );
      },
    );
  }
}
