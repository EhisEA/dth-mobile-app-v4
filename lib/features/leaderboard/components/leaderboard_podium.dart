import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_podium_person.dart";
import "package:flutter/material.dart";

class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({super.key, required this.podium});

  final List<FanLeaderboardEntry> podium;

  FanLeaderboardEntry? _byRank(int rank) {
    for (final e in podium) {
      if (e.rank == rank) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final first = _byRank(1);
    final second = _byRank(2);
    final third = _byRank(3);

    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: AspectRatio(
              aspectRatio: 1.6,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, 0.55, 1.0],
                  ).createShader(bounds);
                },
                child: Image.asset(
                  ImageAssets.leaderboardPodium,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            left: 55,
            bottom: 180,
            child: LeaderboardPodiumPerson(
              entry: second,
              rank: 2,
              avatarSize: 51,
            ),
          ),
          Positioned(
            right: 60,
            bottom: 140,
            child: LeaderboardPodiumPerson(
              entry: third,
              rank: 3,
              avatarSize: 51,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 220,
            child: LeaderboardPodiumPerson(
              entry: first,
              rank: 1,
              avatarSize: 51,
            ),
          ),
        ],
      ),
    );
  }
}
