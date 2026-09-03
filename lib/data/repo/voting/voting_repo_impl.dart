import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/voting/models/voting_contestant.dart";
import "package:dth_v4/features/voting/models/voting_contestant_detail.dart";
import "package:dth_v4/features/voting/models/voting_week_data.dart";
import "package:dth_v4/features/voting/models/vote_credit_quote.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class VotingRepoImpl implements VotingRepo {
  VotingRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<VotingWeekData> fetchVotingWeek() async {
    final response = await _networkService.get(ApiRoute.votingWeek);
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      return VotingWeekData.empty;
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      return VotingWeekData.empty;
    }
    return VotingWeekData.fromJson(data);
  }

  @override
  Future<List<VotingContestant>> fetchContestants({
    required String filter,
  }) async {
    final response = await _networkService.get(
      ApiRoute.votingContestants,
      queryParams: <String, dynamic>{"filter": filter},
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      return const [];
    }
    final data = root["data"];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map>()
        .map((e) => VotingContestant.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  @override
  Future<VotingContestantDetail> fetchContestantDetail(String uid) async {
    final response = await _networkService.get(
      ApiRoute.votingContestantDetail(uid),
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Contestant not found");
    }
    final data = root["data"];
    if (data is! Map) {
      throw ApiFailure(root["message"]?.toString() ?? "Contestant not found");
    }
    return VotingContestantDetail.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<int> submitVote({
    required String votingWeekContestantUid,
    required int voteCount,
  }) async {
    final response = await _networkService.post(
      ApiRoute.votingCast,
      data: <String, dynamic>{
        "voting_week_contestant_uid": votingWeekContestantUid,
        "votes": voteCount,
      },
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid vote response");
    }
    final data = root["data"];
    if (data is! Map) {
      throw ApiFailure(root["message"]?.toString() ?? "Vote failed");
    }
    final remaining = data["remaining_votes"];
    if (remaining is int) return remaining;
    if (remaining is num) return remaining.toInt();
    return int.tryParse(remaining?.toString() ?? "") ?? 0;
  }

  @override
  Future<VoteCreditQuote> quoteCredits({int? amount, int? quantity}) async {
    final hasAmount = amount != null;
    final hasQuantity = quantity != null;
    if (hasAmount == hasQuantity) {
      throw ApiFailure("Provide exactly one of amount or quantity.");
    }
    final query = <String, dynamic>{
      if (hasAmount) "amount": amount,
      if (hasQuantity) "quantity": quantity,
    };
    final response = await _networkService.get(
      ApiRoute.votingCreditsQuote,
      queryParams: query,
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid quote response");
    }
    final data = root["data"];
    if (data is! Map) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not generate credit quote.",
      );
    }
    return VoteCreditQuote.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<SubscriptionPurchaseInit> purchaseCredits({
    required int quantity,
  }) async {
    final response = await _networkService.post(
      ApiRoute.votingCreditsPurchase,
      data: <String, dynamic>{"quantity": quantity},
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid purchase response");
    }
    final data = root["data"];
    if (data is! Map) {
      throw ApiFailure(
        root["message"]?.toString() ?? "Could not start checkout.",
      );
    }
    return SubscriptionPurchaseInit.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> verifyPayment({required String reference}) async {
    await _networkService.get(ApiRoute.paymentVerify(reference));
  }
}

final votingRepositoryProvider = Provider<VotingRepo>((ref) {
  return VotingRepoImpl(networkService: ref.read(networkServiceProvider));
});
