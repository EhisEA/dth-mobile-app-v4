import "dart:async";

import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/voting/voting.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Profile top-right credits controls:
/// - pill tap → available-credits breakdown sheet
/// - plus tap → top-up sheet (skips breakdown)
class ProfileVotingCreditsRow extends StatelessWidget {
  const ProfileVotingCreditsRow({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VotingCreditsChip(
          label: user.votingCreditLabel,
          showAddIcon: false,
          showImage: false,
          onTap: () => unawaited(_openBreakdown(context)),
        ),
        Gap.w4,
        VotingCreditsAddButton(
          onTap: () => unawaited(showTopUpVotingCreditsSheet(context)),
        ),
      ],
    );
  }

  Future<void> _openBreakdown(BuildContext context) async {
    final breakdown =
        user.votingCreditBreakdown ??
        VotingCreditBreakdown(
          title: "Breakdown",
          available: user.votingCredit,
          availableLabel: "${user.votingCredit} available",
          segments: const [],
          sections: const [],
        );
    await showAvailableVotingCreditsSheet(context, breakdown: breakdown);
  }
}
