import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/bottomsheet/show_top_up_voting_credits_sheet.dart";
import "package:dth_v4/features/voting/bottomsheet/show_vote_success_sheet.dart";
import "package:dth_v4/features/voting/components/voting_sponsor_footer.dart";
import "package:dth_v4/features/voting/models/voting_contestant.dart";
import "package:dth_v4/features/voting/models/voting_credits.dart";
import "package:dth_v4/features/voting/view_model/voting_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:intl/intl.dart";

const List<int> _kFallbackVotePresets = [200, 400, 800, 1000];

Future<void> showVoteForContestantSheet(
  BuildContext context,
  WidgetRef ref, {
  required VotingContestant contestant,
}) {
  final vm = ref.read(votingViewModelProvider);

  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    builder: (sheetContext) => _VoteForContestantSheetBody(
      anchorContext: context,
      contestant: contestant,
      initialCredits: vm.credits,
      votePresets: vm.voteValues.isNotEmpty
          ? vm.voteValues
          : _kFallbackVotePresets,
    ),
  );
}

class _VoteForContestantSheetBody extends ConsumerStatefulWidget {
  const _VoteForContestantSheetBody({
    required this.anchorContext,
    required this.contestant,
    required this.initialCredits,
    required this.votePresets,
  });

  /// The screen context that opened this sheet — stays mounted after the sheet
  /// pops (unlike this sheet's own route context) and sits below the app
  /// Overlay, so the success sheet can be shown from it safely.
  final BuildContext anchorContext;
  final VotingContestant contestant;
  final VotingCredits initialCredits;
  final List<int> votePresets;

  @override
  ConsumerState<_VoteForContestantSheetBody> createState() =>
      _VoteForContestantSheetBodyState();
}

class _VoteForContestantSheetBodyState
    extends ConsumerState<_VoteForContestantSheetBody> {
  static final _numberFormat = NumberFormat.decimalPattern();

  late int? _selectedAmount;

  @override
  void initState() {
    super.initState();
    _selectedAmount = _defaultSelection(widget.initialCredits.remaining);
  }

  int? _defaultSelection(int remaining) {
    if (remaining <= 0) {
      return widget.votePresets.isNotEmpty ? widget.votePresets.first : null;
    }
    final preferred = [...widget.votePresets]..sort((a, b) => b.compareTo(a));
    for (final preset in preferred) {
      if (remaining >= preset) return preset;
    }
    return null;
  }

  int _requestedVoteCount(int remaining) {
    if (_selectedAmount == null) return remaining;
    return _selectedAmount!;
  }

  /// Credits the user is short by for the current selection — 0 when the
  /// selection is affordable. Drives the top-up CTA below.
  int _shortfall(int remaining) {
    if (remaining <= 0) {
      return _selectedAmount ?? 0;
    }
    final requested = _requestedVoteCount(remaining);
    return requested > remaining ? requested - remaining : 0;
  }

  int _resolvedVoteCount(VotingCredits credits) {
    final remaining = credits.remaining;
    if (remaining <= 0) return 0;
    if (_selectedAmount == null) return remaining;
    final selected = _selectedAmount!;
    if (selected < 1) return 1;
    if (selected > remaining) return remaining;
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(votingViewModelProvider);
    final credits = vm.credits;
    final remaining = credits.remaining;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final voteCount = _resolvedVoteCount(credits);
    final shortfall = _shortfall(remaining);
    final needsTopUp = shortfall > 0 || remaining <= 0;
    final selectionValid = !needsTopUp && voteCount > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText.medium(
                      "Vote for contestant",
                      fontSize: 18,
                      color: AppColors.tertiary60,
                      textAlign: TextAlign.center,
                    ),
                    Gap.h6,
                    AppText.regular(
                      "Choose how many votes you'd like to cast.",
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.blackTint20,
                      textAlign: TextAlign.center,
                      multiText: true,
                    ),
                    Gap.h16,
                    _WeeklyVotesBadge(remaining: remaining),
                    Gap.h16,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        // Every preset stays tappable: picking one the user
                        // can't afford is how they express intent, and the CTA
                        // below turns into "Top up credits" for the shortfall.
                        for (final preset in widget.votePresets)
                          _VoteAmountChip(
                            label: _numberFormat.format(preset),
                            selected: _selectedAmount == preset,
                            enabled: true,
                            onTap: () =>
                                setState(() => _selectedAmount = preset),
                          ),
                        _VoteAmountChip(
                          label: "Max",
                          selected: _selectedAmount == null,
                          enabled: true,
                          onTap: () => setState(() => _selectedAmount = null),
                        ),
                      ],
                    ),
                    if (needsTopUp) ...[
                      Gap.h16,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AppText.medium(
                          _shortfallMessage(shortfall, remaining),
                          centered: true,
                          fontSize: 13,
                          color: AppColors.redTint35,
                        ),
                      ),
                    ],
                    Gap.h32,
                    if (needsTopUp)
                      AppButton.primary(
                        text: "Top up credits",
                        press: _openTopUp,
                      )
                    else
                      AppButton.primary(
                        text: "Vote",
                        isLoading: vm.isVoteBusy,
                        enabled: selectionValid && !vm.isVoteBusy,
                        press: () => unawaited(_submit(voteCount)),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: AppColors.white,
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

  Future<void> _submit(int voteCount) async {
    if (voteCount <= 0) return;
    final castUid = widget.contestant.votingWeekContestantUid?.trim() ?? "";
    if (castUid.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Voting",
        message: "This contestant is not available for voting right now.",
      );
      return;
    }
    HapticFeedback.mediumImpact();
    final ok = await ref
        .read(votingViewModelProvider)
        .vote(votingWeekContestantUid: castUid, voteCount: voteCount);
    if (!ok || !mounted) return;

    final contestantName = widget.contestant.name;
    Navigator.of(context).pop();
    // Show the success sheet from the opener's still-mounted context, not this
    // sheet's just-popped route context (which lacks an Overlay once popped).
    final anchor = widget.anchorContext;
    if (!anchor.mounted) return;
    await showVoteSuccessSheet(
      anchor,
      voteCount: voteCount,
      contestantName: contestantName,
    );
  }

  String _shortfallMessage(int shortfall, int remaining) {
    if (shortfall <= 0) {
      return "You don’t have any voting credits left. Top up to keep voting.";
    }
    final needed = _numberFormat.format(shortfall);
    final votes = _numberFormat.format(_requestedVoteCount(remaining));
    return "You need $needed more credits to cast $votes votes.";
  }

  void _openTopUp() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    // Shown from the opener's context: this sheet's route context loses its
    // Overlay once popped (same reason as the success sheet above).
    final anchor = widget.anchorContext;
    if (!anchor.mounted) return;
    unawaited(showTopUpVotingCreditsSheet(anchor));
  }
}

class _WeeklyVotesBadge extends StatelessWidget {
  const _WeeklyVotesBadge({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.decimalPattern().format(remaining);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xffE5FBF0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(SvgAssets.voteStar, width: 14, height: 14),
            Gap.w6,
            AppText.regular(
              "You have ",
              fontSize: 12,
              color: AppColors.primary,
            ),
            AppText.semiBold(
              "$formatted voting credits",
              fontSize: 12,
              color: AppColors.primary,
            ),
            AppText.regular(
              " available",
              fontSize: 12,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteAmountChip extends StatelessWidget {
  const _VoteAmountChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.greyTint25;
    final textColor = enabled ? AppColors.tertiary60 : AppColors.tint10;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(100),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText.regular(
                  label,
                  fontSize: 16,
                  color: textColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (selected) ...[
                  Gap.w4,
                  Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
