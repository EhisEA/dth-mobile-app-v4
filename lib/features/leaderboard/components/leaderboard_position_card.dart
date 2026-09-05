import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_avatar.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_helpers.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class LeaderboardPositionCard extends StatelessWidget {
  const LeaderboardPositionCard({super.key, required this.entry});

  final FanLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bold(
            "YOUR POSITION",
            fontSize: 9,
            letterSpacing: 1.8,
            color: AppColors.blackTint20,
          ),
          Gap.h8,
          Row(
            children: [
              LeaderboardAvatar(
                avatarUrl: entry.avatar,
                frameAsset: leaderboardFrameAsset(
                  rank: entry.rank,
                  isYou: true,
                ),
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
