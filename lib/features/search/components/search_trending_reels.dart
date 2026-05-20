import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/stories/stories.dart";
import "package:dth_v4/features/stories/view_model/reels_cache.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SearchTrendingReels extends ConsumerStatefulWidget {
  const SearchTrendingReels({super.key});

  @override
  ConsumerState<SearchTrendingReels> createState() =>
      _SearchTrendingReelsState();
}

class _SearchTrendingReelsState extends ConsumerState<SearchTrendingReels> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cache = ref.read(reelsCacheProvider);
      if (cache.orderedReels.isEmpty) {
        unawaited(_prefetchReels());
      }
    });
  }

  /// Only when the shared cache is empty (e.g. user opened Search before Home).
  Future<void> _prefetchReels() async {
    try {
      final result = await ref
          .read(timelineRepositoryProvider)
          .fetchTimelineReels();
      if (!mounted) return;
      ref.read(reelsCacheProvider).upsertAll(result.items);
    } on ApiFailure {
      // Same as home secondary strip — silent failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    final reelEnabled =
        ref.watch(appModulesStateProvider).appModules.value?.reel == true;
    if (!reelEnabled) return const SizedBox.shrink();

    final cache = ref.watch(reelsCacheProvider);
    final stories = cache.orderedReels
        .map(storyFromTimelineReel)
        .toList(growable: false);
    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.medium("Trending Reels", color: AppColors.black, fontSize: 12),
        Gap.h8,
        StoriesBar(
          stories: stories,
          onStoryTap: (story) {
            MobileNavigationService.instance.push(
              StoriesView.path,
              extra: {RoutingArgumentKey.reelUid: story.uid},
            );
          },
        ),
      ],
    );
  }
}
