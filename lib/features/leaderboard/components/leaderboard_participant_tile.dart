import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_avatar.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_helpers.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class LeaderboardParticipantTile extends StatelessWidget {
  const LeaderboardParticipantTile({super.key, required this.entry});

  final FanLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LeaderboardAvatar(
                avatarUrl: entry.avatar,
                frameAsset: leaderboardFrameAsset(rank: entry.rank),
                size: 40,
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.medium(
                      leaderboardDisplayName(entry),
                      fontSize: 16,
                      color: AppColors.tertiary60,
                      maxLines: 1,
                      letterSpacing: -0.3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h(2),
                    AppText.regular(
                      "${leaderboardOrdinal(entry.rank)} position",
                      fontSize: 12,
                      color: AppColors.blackTint20,
                    ),
                  ],
                ),
              ),
              AppText.bold(
                "${entry.points} pts",
                fontSize: 16,
                color: AppColors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
