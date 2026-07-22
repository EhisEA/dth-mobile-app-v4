import "dart:async";

import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/voting/models/voting_contestant.dart";
import "package:dth_v4/features/voting/models/voting_contestant_detail.dart";
import "package:dth_v4/features/voting/models/voting_credits.dart";
import "package:dth_v4/features/voting/models/voting_tutorial.dart";
import "package:dth_v4/features/voting/models/voting_week_data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

enum VotingFilter { upForEviction, allContestants }

class VotingViewModel extends BaseChangeNotifierViewModel {
  VotingViewModel(this._repo);

  final VotingRepo _repo;

  static const _loadKey = "votingLoad";
  static const _voteKey = "votingVote";
  static const _detailKey = "contestantDetailLoad";
  static const _fallbackVoteValues = [200, 400, 800, 1000];

  VotingFilter filter = VotingFilter.upForEviction;
  VotingCredits credits = const VotingCredits(used: 0, total: 0);
  List<VotingContestant> upForEviction = const [];
  List<VotingContestant> allContestants = const [];
  List<int> voteValues = _fallbackVoteValues;
  VotingTutorial? tutorial;
  String weekUid = "";
  String weekTitle = "";
  DateTime? weekEndsAt;
  VotingContestantDetail? contestantDetail;
  String? _detailUid;
  String? _loadedDetailUid;
  bool _weekLoaded = false;

  /// True after [preloadWeek] or a successful week fetch in [load]/silentRefresh].
  bool get weekLoaded => _weekLoaded;

  ViewModelState get loadState =>
      getState(_loadKey) ?? const ViewModelState.busy();

  ViewModelState get detailLoadState =>
      getState(_detailKey) ?? const ViewModelState.idle();

  /// The loaded detail, but only when it belongs to [uid]. Returns null while a
  /// different (stale) contestant's detail is still in [contestantDetail], so a
  /// freshly-opened view never paints the previous contestant.
  VotingContestantDetail? contestantDetailFor(String uid) =>
      _loadedDetailUid == uid.trim() ? contestantDetail : null;

  /// Detail load state scoped to [uid]. Reports busy until this uid becomes the
  /// most-recently-requested one, so the first frame of a newly-opened view
  /// shows the skeleton instead of another contestant's cached data or state.
  ViewModelState detailStateFor(String uid) =>
      _detailUid == uid.trim() ? detailLoadState : const ViewModelState.busy();

  bool get isVoteBusy =>
      getState(_voteKey)?.maybeWhen(busy: () => true, orElse: () => false) ??
      false;

  List<VotingContestant> get filteredContestants =>
      filter == VotingFilter.upForEviction ? upForEviction : allContestants;

  List<VotingContestant> contestantsFor(VotingFilter tab) =>
      tab == VotingFilter.upForEviction ? upForEviction : allContestants;

  bool get canVote => credits.hasCreditsRemaining && !isVoteBusy;

  /// Splash prefetch: week/credits/tutorial only (no contestant lists).
  Future<void> preloadWeek() async {
    try {
      final week = await _repo.fetchVotingWeek();
      _applyWeek(week);
      notifyListeners();
    } on ApiFailure {
      // Background prefetch — VotingView will load normally if this fails.
    }
  }

  Future<void> load() async {
    setState(_loadKey, const ViewModelState.busy());
    try {
      final results = await Future.wait([
        _repo.fetchVotingWeek(),
        _repo.fetchContestants(filter: "up_for_eviction"),
        _repo.fetchContestants(filter: "all"),
      ]);
      _applyWeek(results[0] as VotingWeekData);
      upForEviction = results[1] as List<VotingContestant>;
      allContestants = results[2] as List<VotingContestant>;
      setState(_loadKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      setState(_loadKey, ViewModelState.error(e));
    }
  }

  Future<void> refresh() => silentRefresh();

  /// Fetches week + both lists without flipping busy/skeleton states.
  Future<void> silentRefresh() async {
    try {
      final results = await Future.wait([
        _repo.fetchVotingWeek(),
        _repo.fetchContestants(filter: "up_for_eviction"),
        _repo.fetchContestants(filter: "all"),
      ]);
      final week = results[0] as VotingWeekData;
      // A malformed/empty background response must not wipe good credits or the
      // week title/tutorial — keep the last good week when the fetch is empty.
      if (!week.isEmpty) _applyWeek(week);
      upForEviction = results[1] as List<VotingContestant>;
      allContestants = results[2] as List<VotingContestant>;
      notifyListeners();
    } on ApiFailure {
      // Keep last good data on silent failure.
    }
  }

  void _applyWeek(VotingWeekData week) {
    credits = week.credits;
    voteValues = week.voteValues.isNotEmpty
        ? week.voteValues
        : _fallbackVoteValues;
    tutorial = week.tutorial;
    weekUid = week.uid;
    weekTitle = week.title;
    weekEndsAt = week.endsAt;
    _weekLoaded = true;
  }

  void setFilter(VotingFilter next) {
    if (filter == next) return;
    filter = next;
    notifyListeners();
  }

  Future<void> loadContestantDetail(String uid) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return;

    if (_loadedDetailUid == trimmed &&
        contestantDetail != null &&
        detailLoadState.maybeWhen(idle: () => true, orElse: () => false)) {
      return;
    }

    _detailUid = trimmed;
    setState(_detailKey, const ViewModelState.busy());
    try {
      final detail = await _repo.fetchContestantDetail(trimmed);
      // Ignore a late response that a newer request has superseded.
      if (_detailUid != trimmed) return;
      contestantDetail = detail;
      _loadedDetailUid = trimmed;
      setState(_detailKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      if (_detailUid != trimmed) return;
      contestantDetail = null;
      _loadedDetailUid = null;
      setState(_detailKey, ViewModelState.error(e));
    }
  }

  Future<bool> vote({
    required String votingWeekContestantUid,
    required int voteCount,
  }) async {
    final castUid = votingWeekContestantUid.trim();
    if (!canVote || castUid.isEmpty || voteCount <= 0) {
      return false;
    }
    if (voteCount > credits.remaining) {
      DthFlushBar.instance.showError(
        title: "Voting",
        message: "You do not have enough votes remaining.",
      );
      return false;
    }

    setState(_voteKey, const ViewModelState.busy());
    try {
      final remaining = await _repo.submitVote(
        votingWeekContestantUid: castUid,
        voteCount: voteCount,
      );
      credits = credits.copyWith(
        used: (credits.total - remaining).clamp(0, credits.total),
      );
      setState(_voteKey, const ViewModelState.idle());
      // Refresh lists after the cast sheet can pop; don't block success UI.
      unawaited(silentRefresh());
      return true;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(title: "Voting", message: e.message);
      setState(_voteKey, ViewModelState.error(e));
      return false;
    }
  }
}

final votingViewModelProvider = ChangeNotifierProvider<VotingViewModel>((ref) {
  return VotingViewModel(ref.read(votingRepositoryProvider));
});
