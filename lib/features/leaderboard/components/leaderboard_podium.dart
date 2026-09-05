import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/leaderboard_podium_person.dart";
import "package:flutter/material.dart";

class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({super.key, required this.podium});

  final List<FanLeaderboardEntry> podium;

  /// Intrinsic asset sizes — keep relative block sizes / display widths correct.
  static const _w1 = 490.0;
  static const _h1 = 850.0;
  static const _w2 = 472.0;
  static const _h2 = 720.0;
  static const _w3 = 476.0;
  static const _h3 = 600.0;

  /// Approximate height of avatar + name + points pill.
  static const _personStackHeight = 100.0;

  static const _horizontalPadding = 20.0;

  /// How much 2/3 tuck under 1 when spanning full width.
  static const _overlap = 20.0;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final usable = (width - _horizontalPadding * 2).clamp(0.0, width);

        // Natural aspect ratios → scale so the three drawn widths fill [pad, width-pad]
        // with a little overlap (2+1+3 widths − 2×overlap ≈ usable).
        const naturalFirstH = 180.0;
        final naturalSecondH = naturalFirstH * (_h2 / _h1);
        final naturalThirdH = naturalFirstH * (_h3 / _h1);
        final naturalSpan =
            naturalFirstH * (_w1 / _h1) +
            naturalSecondH * (_w2 / _h2) +
            naturalThirdH * (_w3 / _h3);
        final targetSpan = usable + _overlap * 2;
        final scale = (targetSpan / naturalSpan).clamp(0.85, 1.45);

        final firstBlockHeight = naturalFirstH * scale;
        final secondBlockHeight = naturalSecondH * scale;
        final thirdBlockHeight = naturalThirdH * scale;

        final firstDrawW = firstBlockHeight * (_w1 / _h1);
        final secondDrawW = secondBlockHeight * (_w2 / _h2);
        final thirdDrawW = thirdBlockHeight * (_w3 / _h3);

        final slotWidth = [
          firstDrawW,
          secondDrawW,
          thirdDrawW,
          112.0,
        ].reduce((a, b) => a > b ? a : b);

        // Full width: 2 flush to left padding, 3 flush to right padding.
        final secondCenterX = _horizontalPadding + secondDrawW / 2;
        final thirdCenterX = width - _horizontalPadding - thirdDrawW / 2;
        final firstCenterX = width / 2;

        final totalHeight = _personStackHeight + firstBlockHeight - 15;

        Widget block({
          required double centerX,
          required double blockHeight,
          required String asset,
        }) {
          return Positioned(
            left: centerX - slotWidth / 2,
            bottom: 0,
            width: slotWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: _personStackHeight - 14),
              child: SizedBox(
                height: blockHeight,
                width: slotWidth,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0.0, 0.72, 1.0],
                    ).createShader(bounds);
                  },
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          );
        }

        Widget person({
          required double centerX,
          required FanLeaderboardEntry? entry,
          required int rank,
          double? blockHeight,
        }) {
          // 1st stays top-aligned (already sits on its podium). 2 & 3 are
          // anchored to their shorter block tops so they don't float.
          if (blockHeight != null) {
            return Positioned(
              left: centerX - slotWidth / 2,
              bottom: blockHeight - 14,
              width: slotWidth,
              child: LeaderboardPodiumPerson(
                entry: entry,
                rank: rank,
                avatarSize: 51,
                maxWidth: slotWidth,
              ),
            );
          }
          return Positioned(
            left: centerX - slotWidth / 2,
            top: 0,
            width: slotWidth,
            child: LeaderboardPodiumPerson(
              entry: entry,
              rank: rank,
              avatarSize: 51,
              maxWidth: slotWidth,
            ),
          );
        }

        return SizedBox(
          height: totalHeight,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Blocks — 1 last so it sits in front of 2 & 3.
              block(
                centerX: secondCenterX,
                blockHeight: secondBlockHeight,
                asset: ImageAssets.leaderboardPodium2,
              ),
              block(
                centerX: thirdCenterX,
                blockHeight: thirdBlockHeight,
                asset: ImageAssets.leaderboardPodium3,
              ),
              block(
                centerX: firstCenterX,
                blockHeight: firstBlockHeight,
                asset: ImageAssets.leaderboardPodium1,
              ),
              // People above every block so points/names stay visible.
              person(
                centerX: secondCenterX,
                entry: second,
                rank: 2,
                blockHeight: secondBlockHeight,
              ),
              person(
                centerX: thirdCenterX,
                entry: third,
                rank: 3,
                blockHeight: thirdBlockHeight,
              ),
              person(centerX: firstCenterX, entry: first, rank: 1),
            ],
          ),
        );
      },
    );
  }
}
