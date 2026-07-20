import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/models/voting_contestant.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

enum ContestantCardAction { vote, viewDetails }

class ContestantVoteCard extends StatelessWidget {
  const ContestantVoteCard({
    super.key,
    required this.contestant,
    required this.action,
    required this.onOpenAbout,
    this.onVote,
    this.voteEnabled = true,
  });

  final VotingContestant contestant;
  final ContestantCardAction action;
  final VoidCallback onOpenAbout;
  final VoidCallback? onVote;
  final bool voteEnabled;

  static const double cardHeight = 244;
  static const double _blurHeight = 130;

  Widget _buildPhoto(BuildContext context) {
    Widget photo = CachedNetworkImage(
      imageUrl: contestant.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) =>
          ShimmerBox(baseColor: AppColors.baseShimmer(context)),
      errorWidget: (_, __, ___) => ColoredBox(
        color: AppColors.baseShimmer(context),
        child: Icon(
          Icons.person_outline_rounded,
          color: AppColors.tint15,
          size: 48,
        ),
      ),
    );
    if (!contestant.isEvicted) return photo;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: photo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showVoteButton =
        action == ContestantCardAction.vote && contestant.canCastVote;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onOpenAbout();
        },
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: cardHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPhoto(context),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: _blurHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRect(
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x66000000),
                              Colors.black,
                            ],
                            stops: [0.0, 0.4, 1.0],
                          ).createShader(bounds),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 12,
                              sigmaY: 12,
                              tileMode: TileMode.clamp,
                            ),
                            child: OverflowBox(
                              alignment: Alignment.bottomCenter,
                              maxHeight: cardHeight,
                              minHeight: cardHeight,
                              child: SizedBox(
                                height: cardHeight,
                                width: double.infinity,
                                child: _buildPhoto(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xff010101).withValues(alpha: 0),
                              const Color(0xff010101).withValues(alpha: 0.2),
                              const Color(0xff010101).withValues(alpha: 0.7),
                            ],
                            stops: const [0.0, 0.35, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (contestant.isEvicted)
                  Center(
                    child: Image.asset(
                      ImageAssets.evicted,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                    decoration: BoxDecoration(
                      color: AppColors.scaffold,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          SvgAssets.voteCircleStar,
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                        Gap.w4,
                        Flexible(
                          child: AppText.semiBold(
                            contestant.code.toUpperCase(),
                            fontSize: 10,
                            color: AppColors.primary,
                            letterSpacing: 0.2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.bold(
                              contestant.name.toUpperCase(),
                              fontSize: 16,
                              color: AppColors.scaffold,
                              maxLines: 2,
                              letterSpacing: -0.1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (contestant.bio != null) ...[
                              Gap.h4,
                              AppText.regular(
                                contestant.bio!,
                                fontSize: 13,
                                color: AppColors.scaffold,
                                maxLines: 2,
                                letterSpacing: -0.25,
                                height: 1.25,
                                overflow: TextOverflow.ellipsis,
                                multiText: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (showVoteButton) ...[
                        Gap.w24,
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: voteEnabled && onVote != null
                              ? () {
                                  HapticFeedback.lightImpact();
                                  onVote!();
                                }
                              : null,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 160),
                            opacity: voteEnabled ? 1 : 0.55,
                            child: const _CardActionButton(
                              action: ContestantCardAction.vote,
                            ),
                          ),
                        ),
                      ] else if (action ==
                          ContestantCardAction.viewDetails) ...[
                        Gap.w24,
                        SvgPicture.asset(SvgAssets.voteForwardArrow),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({required this.action});

  final ContestantCardAction action;

  @override
  Widget build(BuildContext context) {
    return action == ContestantCardAction.vote
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 31, vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(100),
            ),
            child: AppText.regular(
              "Vote",
              fontSize: 14,
              color: AppColors.primary,
            ),
          )
        : SvgPicture.asset(SvgAssets.voteForwardArrow);
  }
}

class ContestantVoteCardSkeleton extends StatelessWidget {
  const ContestantVoteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: ContestantVoteCard.cardHeight,
        width: double.infinity,
        child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
      ),
    );
  }
}
