import "package:dth_v4/data/data.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class PollViewModel extends BaseChangeNotifierViewModel {
  PollViewModel(this._pollRepo);

  final PollRepo _pollRepo;

  final ValueNotifier<PollModel?> poll = ValueNotifier<PollModel?>(null);

  static const String _voteStateKey = "pollVoteStateKey";

  ViewModelState get voteState =>
      getState(_voteStateKey) ?? const ViewModelState.idle();

  bool get isVoteBusy =>
      voteState.maybeWhen(busy: () => true, orElse: () => false);

  Future<void> loadPoll() async {
    try {
      final result = await _pollRepo.fetchPoll();
      poll.value = result;
    } on ApiFailure {
      // Background fetch on home — fail silently. The poll module is
      // optional and the UI degrades gracefully when [poll.value] stays null.
    }
  }

  Future<void> vote(String optionUid) async {
    final previous = poll.value;
    if (previous == null ||
        previous.isClosed ||
        previous.hasVoted ||
        isVoteBusy ||
        optionUid.trim().isEmpty) {
      return;
    }

    poll.value = _projectVote(previous, optionUid);
    setState(_voteStateKey, const ViewModelState.busy());

    try {
      final updated = await _pollRepo.submitVote(
        pollUid: previous.uid,
        optionUid: optionUid,
      );
      poll.value = updated;
      setState(_voteStateKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      // Rolling the optimistic vote back is the user-visible failure
      // signal — no toast needed.
      poll.value = previous;
      setState(_voteStateKey, ViewModelState.error(e));
    }
  }

  PollModel _projectVote(PollModel current, String optionUid) {
    final newTotal = current.totalVotes + 1;
    final projectedOptions = current.options.map((option) {
      final isSelected = option.uid == optionUid;
      final newVotes = isSelected ? option.votesCount + 1 : option.votesCount;
      final newPercentage = newTotal == 0
          ? 0
          : ((newVotes / newTotal) * 100).round();
      return PollOptionModel(
        uid: option.uid,
        name: option.name,
        votesCount: newVotes,
        percentage: newPercentage,
      );
    }).toList();

    return PollModel(
      uid: current.uid,
      title: current.title,
      subtitle: current.subtitle,
      question: current.question,
      description: current.description,
      totalVotes: newTotal,
      totalVotesDescription: current.totalVotesDescription,
      status: current.status,
      hasEnded: current.hasEnded,
      timeLeft: current.timeLeft,
      endsAt: current.endsAt,
      hasVoted: true,
      votedOptionUid: optionUid,
      options: projectedOptions,
    );
  }

  @override
  void dispose() {
    poll.dispose();
    super.dispose();
  }
}

final pollViewModelProvider = ChangeNotifierProvider<PollViewModel>((ref) {
  return PollViewModel(ref.read(pollRepositoryProvider));
});
