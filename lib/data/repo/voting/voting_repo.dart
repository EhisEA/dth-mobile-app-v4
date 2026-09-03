import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/voting/models/voting_contestant.dart";
import "package:dth_v4/features/voting/models/voting_contestant_detail.dart";
import "package:dth_v4/features/voting/models/voting_week_data.dart";
import "package:dth_v4/features/voting/models/vote_credit_quote.dart";

abstract class VotingRepo {
  Future<VotingWeekData> fetchVotingWeek();
  Future<List<VotingContestant>> fetchContestants({required String filter});
  Future<VotingContestantDetail> fetchContestantDetail(String uid);

  /// Casts votes; returns remaining weekly credits from the API.
  Future<int> submitVote({
    required String votingWeekContestantUid,
    required int voteCount,
  });

  /// Money-first or credits-first quote. Supply exactly one of [amount] /
  /// [quantity].
  Future<VoteCreditQuote> quoteCredits({int? amount, int? quantity});

  Future<SubscriptionPurchaseInit> purchaseCredits({required int quantity});

  Future<void> verifyPayment({required String reference});
}
