import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_avatar.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_helpers.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_points_pill.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class LeaderboardPodiumPerson extends StatelessWidget {
  const LeaderboardPodiumPerson({
    super.key,
    required this.entry,
    required this.rank,
    required this.avatarSize,
  });

  final FanLeaderboardEntry? entry;
  final int rank;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LeaderboardAvatar(
          avatarUrl: entry!.avatar,
          frameAsset: leaderboardFrameAsset(rank: rank),
          size: avatarSize,
        ),
        Gap.h4,
        AppText.medium(
          leaderboardDisplayName(entry!),
          fontSize: 14,
          color: AppColors.mainBlack,
          maxLines: 1,
          height: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Gap.h4,
        LeaderboardPointsPill(points: entry!.points),
      ],
    );
  }
}
