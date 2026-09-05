import "package:dth_v4/data/models/model.dart";

abstract class FanLeaderboardRepo {
  /// `GET /fan-leaderboard` — first page when [cursor] is null.
  Future<FanLeaderboardData> fetch({String? cursor});
}
