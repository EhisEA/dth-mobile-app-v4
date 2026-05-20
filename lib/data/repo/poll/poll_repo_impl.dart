import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class PollRepoImpl implements PollRepo {
  PollRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<PollModel?> fetchPoll() async {
    final response = await _networkService.get(ApiRoute.polls);
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      return null;
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      return null;
    }
    return PollModel.fromJson(data);
  }

  @override
  Future<PollModel> submitVote({
    required String pollUid,
    required String optionUid,
  }) async {
    final response = await _networkService.post(
      ApiRoute.pollVote(pollUid),
      data: PollVoteRequest(optionUid: optionUid).toJson(),
    );
    final root = response.data as Map<String, dynamic>;
    final data = root["data"] as Map<String, dynamic>;
    return PollModel.fromJson(data);
  }
}

final pollRepositoryProvider = Provider<PollRepo>((ref) {
  return PollRepoImpl(networkService: ref.read(networkServiceProvider));
});
