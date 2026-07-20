import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/stories/stories.dart";
import "package:dth_v4/features/stories/view_model/reels_cache.dart";
import "package:dth_v4/features/voting/voting.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class AboutContestantView extends ConsumerStatefulWidget {
  const AboutContestantView({super.key, required this.contestantUid});

  static const String path = NavigatorRoutes.aboutContestant;

  final String contestantUid;

  @override
  ConsumerState<AboutContestantView> createState() =>
      _AboutContestantViewState();
}

class _AboutContestantViewState extends ConsumerState<AboutContestantView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(votingViewModelProvider)
            .loadContestantDetail(widget.contestantUid),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(votingViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const DthAppBar(title: "About Contestant"),
      bottomNavigationBar: vm.detailLoadState.maybeWhen(
        idle: () {
          final detail = vm.contestantDetail;
          if (detail == null ||
              !detail.isVotable ||
              (detail.votingWeekContestantUid?.trim().isEmpty ?? true)) {
            return null;
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: AppButton.primary(
              text: "Vote now",
              enabled: !vm.isVoteBusy,
              isLoading: vm.isVoteBusy,
              press: () => showVoteForContestantSheet(
                context,
                ref,
                contestant: detail.toContestant,
              ),
            ),
          );
        },
        orElse: () => null,
      ),
      body: vm.detailLoadState.when(
        busy: () => const _AboutContestantSkeleton(),
        error: (failure) => EmptyState(
          illustration: Icon(
            Icons.person_outline_rounded,
            size: 56,
            color: AppColors.tint15,
          ),
          title: "Could not load contestant",
          subtitle: failure.message,
          showDashedDivider: false,
          onRetry: () => unawaited(
            ref
                .read(votingViewModelProvider)
                .loadContestantDetail(widget.contestantUid),
          ),
        ),
        idle: () {
          final detail = vm.contestantDetail;
          if (detail == null) {
            return EmptyState(
              illustration: Icon(
                Icons.person_outline_rounded,
                size: 56,
                color: AppColors.tint15,
              ),
              title: "Contestant not found",
              subtitle: "This contestant may no longer be available.",
              showDashedDivider: false,
            );
          }
          return _AboutContestantBody(detail: detail);
        },
      ),
    );
  }
}

class _AboutContestantBody extends StatelessWidget {
  const _AboutContestantBody({required this.detail});

  final VotingContestantDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4.5 / 3,
            child: CachedNetworkImage(
              imageUrl: detail.imageUrl,
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
            ),
          ),
        ),
        Gap.h16,
        AppText.medium(
          detail.tagline.trim().isEmpty
              ? detail.name
              : "${detail.name}: ${detail.tagline}",
          fontSize: 18,
          color: AppColors.mainBlack,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        Gap.h4,
        _UserIdRow(code: detail.code),
        Gap.h24,
        AppText.medium(
          "Contestant's Biography",
          fontSize: 14,
          color: AppColors.mainBlack,
        ),
        Gap.h8,
        AppText.regular(
          detail.biography,
          fontSize: 14,
          height: 1.5,
          color: AppColors.blackTint20,
          multiText: true,
        ),
        const VotingSponsorImageCarousel(),
        if (detail.performances.isNotEmpty) ...[
          Gap.h24,
          AppText.medium(
            "Past Performances",
            fontSize: 16,
            color: AppColors.mainBlack,
          ),
          Gap.h12,
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.performances.length,
              separatorBuilder: (_, __) => Gap.w12,
              itemBuilder: (_, index) {
                return _PerformanceCard(
                  performance: detail.performances[index],
                );
              },
            ),
          ),
        ],
        Gap.h10,
      ],
    );
  }
}

class _UserIdRow extends StatelessWidget {
  const _UserIdRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText.semiBold(
          "Contestant ID: ",
          fontSize: 13,
          color: AppColors.blackTint20,
        ),
        AppText.regular(
          code.toUpperCase(),
          fontSize: 13,
          color: AppColors.blackTint20,
        ),
        Gap.w6,
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            HapticFeedback.lightImpact();
            DthFlushBar.instance.showCopySuccess(
              title: "Copied to clipboard",
              message: "The ID has been copied to your clipboard",
            );
          },
          behavior: HitTestBehavior.opaque,
          child: SvgPicture.asset(
            SvgAssets.copyOutline,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
          ),
        ),
      ],
    );
  }
}

class _PerformanceCard extends ConsumerWidget {
  const _PerformanceCard({required this.performance});

  final VotingContestantPerformance performance;

  static const double _width = 120;
  static const double _height = 180;

  /// Past performances are voting records with a YouTube `video_link`, not
  /// timeline reel uids. Seed [ReelsCache] so [StoriesView] / [ReelPage] can
  /// play them the same way as home reels (fetch by uid would 404 → black).
  void _openPerformance(WidgetRef ref) {
    final url = performance.videoLink.trim();
    final uid = performance.uid.trim();
    if (url.isEmpty && uid.isEmpty) return;
    HapticFeedback.lightImpact();

    if (url.isNotEmpty) {
      final reelUid = uid.isNotEmpty ? uid : url;
      ref
          .read(reelsCacheProvider)
          .upsert(
            TimelineReel(
              uid: reelUid,
              title: performance.title,
              description: "",
              videoType: "youtube",
              videoLink: url,
              videoThumbnail: performance.thumbnailUrl.trim().isEmpty
                  ? null
                  : performance.thumbnailUrl.trim(),
              counts: const TimelinePostCounts(
                comments: 0,
                reactions: 0,
                views: 0,
                shares: 0,
              ),
              createdAt: "",
            ),
          );
      unawaited(
        MobileNavigationService.instance.push(
          StoriesView.path,
          extra: {RoutingArgumentKey.reelUid: reelUid},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openPerformance(ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: _width,
          height: _height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: performance.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    ShimmerBox(baseColor: AppColors.baseShimmer(context)),
                errorWidget: (_, __, ___) =>
                    ColoredBox(color: AppColors.baseShimmer(context)),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x66000000),
                      Color(0xCC000000),
                    ],
                    stops: [0.35, 0.72, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: SvgPicture.asset(
                  SvgAssets.play,
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 10,
                child: AppText.medium(
                  performance.title,
                  fontSize: 11,
                  color: AppColors.white,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  multiText: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutContestantSkeleton extends StatelessWidget {
  const _AboutContestantSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
          ),
        ),
        Gap.h16,
        SizedBox(
          height: 22,
          width: double.infinity,
          child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
        ),
        Gap.h8,
        SizedBox(
          height: 16,
          width: 160,
          child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
        ),
        Gap.h24,
        SizedBox(
          height: 18,
          width: 180,
          child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
        ),
        Gap.h8,
        SizedBox(
          height: 14,
          width: double.infinity,
          child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
        ),
        Gap.h6,
        SizedBox(
          height: 14,
          width: double.infinity,
          child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
        ),
        Gap.h24,
        SizedBox(
          height: 18,
          width: 160,
          child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
        ),
        Gap.h12,
        SizedBox(
          height: 180,
          child: Row(
            children: [
              SizedBox(
                height: 180,
                width: 120,
                child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
              ),
              Gap.w12,
              SizedBox(
                height: 180,
                width: 120,
                child: ShimmerBox(baseColor: AppColors.baseShimmer(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
