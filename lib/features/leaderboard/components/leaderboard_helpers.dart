import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";

String leaderboardOrdinal(int rank) {
  if (rank <= 0) return "$rank";
  final mod100 = rank % 100;
  if (mod100 >= 11 && mod100 <= 13) return "${rank}th";
  switch (rank % 10) {
    case 1:
      return "${rank}st";
    case 2:
      return "${rank}nd";
    case 3:
      return "${rank}rd";
    default:
      return "${rank}th";
  }
}

String leaderboardDisplayName(FanLeaderboardEntry entry) {
  final name = entry.name.trim();
  if (name.isEmpty) return entry.isYou ? "You" : "Fan";
  return name;
}

/// Scalloped frame PNG for podium ranks / list / current user.
String leaderboardFrameAsset({required int rank, bool isYou = false}) {
  if (isYou) return ImageAssets.leaderboardFramePerson;
  switch (rank) {
    case 1:
      return ImageAssets.leaderboardFrame1st;
    case 2:
      return ImageAssets.leaderboardFrame2nd;
    case 3:
      return ImageAssets.leaderboardFrame3rd;
    default:
      return ImageAssets.leaderboardFrameReg;
  }
}
