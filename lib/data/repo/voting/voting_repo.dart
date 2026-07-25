import "package:dth_v4/features/voting/models/voting_contestant.dart";
import "package:dth_v4/features/voting/models/voting_contestant_detail.dart";
import "package:dth_v4/features/voting/models/voting_week_data.dart";

abstract class VotingRepo {
  Future<VotingWeekData> fetchVotingWeek();
  Future<List<VotingContestant>> fetchContestants({required String filter});
  Future<VotingContestantDetail> fetchContestantDetail(String uid);

  /// Casts votes; returns remaining weekly credits from the API.
  Future<int> submitVote({
    required String votingWeekContestantUid,
    required int voteCount,
  });
}
