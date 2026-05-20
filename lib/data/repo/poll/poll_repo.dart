import "package:dth_v4/data/data.dart";

abstract class PollRepo {
  Future<PollModel?> fetchPoll();
  Future<PollModel> submitVote({
    required String pollUid,
    required String optionUid,
  });
}
