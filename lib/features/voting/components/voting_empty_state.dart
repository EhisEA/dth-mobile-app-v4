import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/view_model/voting_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";

/// Voting list empty state using [ImageAssets.voteEmpty].
class VotingEmptyState extends StatelessWidget {
  const VotingEmptyState({super.key, required this.filter, this.onRetry});

  final VotingFilter filter;
  final VoidCallback? onRetry;

  String get _title => filter == VotingFilter.upForEviction
      ? "No Contestants Up for Eviction"
      : "No Contestants Available";

  String get _subtitle => filter == VotingFilter.upForEviction
      ? "There are currently no contestants up for eviction at the moment."
      : "There are no contestants available for voting right now. Check back when voting opens.";

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      illustration: Image.asset(ImageAssets.voteEmpty, fit: BoxFit.contain),
      title: _title,
      subtitle: _subtitle,
      showDashedDivider: false,
      onRetry: onRetry,
    );
  }
}
