import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/data.dart';
import 'package:dth_v4/features/stories/stories.dart';
import 'package:dth_v4/features/stories/view_model/reels_cache.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_utils/flutter_utils.dart';

class SearchTrendingReels extends ConsumerStatefulWidget {
  const SearchTrendingReels({super.key});

  @override
  ConsumerState<SearchTrendingReels> createState() =>
      _SearchTrendingReelsState();
}

class _SearchTrendingReelsState extends ConsumerState<SearchTrendingReels> {
  bool _isLoading = true;
  List<Story> _stories = const [];

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      final result = await ref
          .read(timelineRepositoryProvider)
          .fetchTimelineReels();
      if (!mounted) return;
      ref.read(reelsCacheProvider).upsertAll(result.items);
      setState(() {
        _stories = result.items.map(storyFromTimelineReel).toList();
        _isLoading = false;
      });
    } on ApiFailure {
      if (!mounted) return;
      setState(() {
        _stories = const [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    if (_stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.medium("Trending Reels", color: AppColors.black, fontSize: 12),
        Gap.h8,
        StoriesBar(
          stories: _stories,
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
