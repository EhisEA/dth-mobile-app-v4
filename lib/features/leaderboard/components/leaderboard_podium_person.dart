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
    this.maxWidth,
  });

  final FanLeaderboardEntry? entry;
  final int rank;
  final double avatarSize;

  /// Caps name width so long labels ellipsis instead of shifting the column.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    final nameWidth = maxWidth ?? avatarSize * 2.2;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        // Keep podium labels stable under large accessibility text scales.
        textScaler: MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.1),
      ),
      child: SizedBox(
        width: maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LeaderboardAvatar(
              avatarUrl: entry!.avatar,
              frameAsset: leaderboardFrameAsset(rank: rank),
              size: avatarSize,
            ),
            Gap.h4,
            SizedBox(
              width: nameWidth,
              child: AppText.medium(
                leaderboardDisplayName(entry!),
                fontSize: 14,
                color: AppColors.mainBlack,
                maxLines: 1,
                height: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                centered: true,
              ),
            ),
            Gap.h4,
            LeaderboardPointsPill(points: entry!.points),
          ],
        ),
      ),
    );
  }
}
