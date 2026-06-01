import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/features/stories/components/reel_page.dart";
import "package:dth_v4/features/stories/view_model/reels_feed_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Vertical, swipeable reel viewer (Reels/TikTok style). Opens on [reelUid] and
/// lets the user swipe up/down through the feed. The swipe order + cursor
/// pagination live in [ReelsFeedViewModel]; each page is a [ReelPage] that
/// hydrates itself from [ReelsCache]. Only the active page plays.
class StoriesView extends ConsumerStatefulWidget {
  const StoriesView({super.key, required this.reelUid});

  final String reelUid;

  static const String path = NavigatorRoutes.stories;

  @override
  ConsumerState<StoriesView> createState() => _StoriesViewState();
}

class _StoriesViewState extends ConsumerState<StoriesView> {
  late final PageController _pageController;
  late int _activeIndex;

  @override
  void initState() {
    super.initState();

    // Resolve the starting page from the seeded order (cache-warm on home/search
    // entry, or just the opened reel on a cold deep link).
    final feed = ref.read(reelsFeedViewModelProvider(widget.reelUid));
    final startIndex = feed.uids.indexOf(widget.reelUid);
    _activeIndex = startIndex < 0 ? 0 : startIndex;
    _pageController = PageController(initialPage: _activeIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Fill the pager below the opened reel + obtain the pagination cursor.
      ref.read(reelsFeedViewModelProvider(widget.reelUid)).ensureLoaded();
    });
  }

  // Status-bar style is handled purely by the AnnotatedRegion below (light icons
  // over the dark reel), which reverts to the app's root baseline on pop. No
  // imperative SystemChrome calls here — those race with the AnnotatedRegion
  // during the pop animation and leave the bar stuck (worse under video, which
  // drives constant frames).

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, int count) {
    setState(() => _activeIndex = index);
    // Prefetch the next page as we approach the end of the loaded list.
    if (index >= count - 2) {
      ref.read(reelsFeedViewModelProvider(widget.reelUid)).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uids = ref.watch(
      reelsFeedViewModelProvider(widget.reelUid).select((vm) => vm.uids),
    );

    if (uids.isEmpty) {
      return const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: uids.length,
          onPageChanged: (index) => _onPageChanged(index, uids.length),
          itemBuilder: (context, index) {
            final uid = uids[index];
            return ReelPage(
              key: ValueKey(uid),
              reelUid: uid,
              isActive: index == _activeIndex,
            );
          },
        ),
      ),
    );
  }
}
