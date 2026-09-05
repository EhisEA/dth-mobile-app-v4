import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class FanLeaderboardRepoImpl implements FanLeaderboardRepo {
  FanLeaderboardRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<FanLeaderboardData> fetch({String? cursor}) async {
    final response = await _networkService.get(
      ApiRoute.fanLeaderboard,
      queryParams: _cursorParams(cursor),
    );
    return _parse(response.data);
  }

  Map<String, dynamic>? _cursorParams(String? cursor) {
    if (cursor == null || cursor.isEmpty) return null;
    return {"cursor": cursor};
  }

  FanLeaderboardData _parse(dynamic root) {
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid fan leaderboard response");
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Missing fan leaderboard data");
    }
    return FanLeaderboardData.fromJson(data);
  }
}

final fanLeaderboardRepositoryProvider = Provider<FanLeaderboardRepo>((ref) {
  return FanLeaderboardRepoImpl(
    networkService: ref.read(networkServiceProvider),
  );
});
