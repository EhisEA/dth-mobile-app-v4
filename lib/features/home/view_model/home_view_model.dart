import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/posts/models/post_mapper.dart";
import "package:dth_v4/features/posts/view_model/posts_cache.dart";
import "package:dth_v4/features/stories/models/story.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class HomeViewModel extends BaseChangeNotifierViewModel {
  HomeViewModel(this.userState, this._timelineRepo, this._postsCache);

  final UserState userState;
  final TimelineRepo _timelineRepo;
  final PostsCache _postsCache;

  ValueNotifier<UserModel?> get userModel => userState.user;

  /// Order-only. The actual `Post` objects live in [PostsCache] — the view
  /// derives the list by mapping these uids through `cache.get(uid)`. This
  /// keeps the cache as the single source of truth for post state, so a
  /// like/comment-count mutation on the detail screen is visible here without
  /// any sync code.
  List<String> _postUids = const [];
  List<String> get postUids => _postUids;

  List<Story> _stories = const [];
  List<Story> get stories => _stories;

  String? _nextCursor;
  bool get hasMore => _nextCursor != null;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  Future<void> loadTimeline() async {
    try {
      changeBaseState(const ViewModelState.busy());

      final result = await _timelineRepo.fetchTimeline();
      final posts = result.items.map(postFromTimelinePost).toList();
      _postsCache.upsertAll(posts);
      _postUids = posts.map((p) => p.uid).toList();
      _nextCursor = result.nextCursor;

      try {
        final reelsResult = await _timelineRepo.fetchTimelineReels();
        _stories = reelsResult.items.map(_reelToStory).toList();
      } on ApiFailure {
        _stories = const [];
      }

      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
    }
  }

  Future<void> refreshTimeline() async {
    try {
      final result = await _timelineRepo.fetchTimeline();
      final posts = result.items.map(postFromTimelinePost).toList();
      _postsCache.upsertAll(posts);
      _postUids = posts.map((p) => p.uid).toList();
      _nextCursor = result.nextCursor;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Failed");
      notifyListeners();
      return;
    }

    try {
      final reelsResult = await _timelineRepo.fetchTimelineReels();
      _stories = reelsResult.items.map(_reelToStory).toList();
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Reels");
    }

    notifyListeners();
  }

  Future<void> loadMoreTimeline() async {
    if (!hasMore || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await _timelineRepo.fetchTimeline(cursor: _nextCursor);
      final posts = result.items.map(postFromTimelinePost).toList();
      _postsCache.upsertAll(posts);
      _postUids = [..._postUids, ...posts.map((p) => p.uid)];
      _nextCursor = result.nextCursor;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Load more");
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }
}

Story _reelToStory(TimelineReel r) {
  final thumb = r.media?.thumbnail?.trim();
  final videoThumb = r.videoThumbnail?.trim();
  final mediaUrl = r.media?.url?.trim();
  final imageUrl = (thumb != null && thumb.isNotEmpty)
      ? thumb
      : (videoThumb != null && videoThumb.isNotEmpty)
      ? videoThumb
      : (mediaUrl ?? "");
  final label = r.title.trim().isNotEmpty ? r.title.trim() : "Reel";
  return Story(imageUrl: imageUrl, label: label);
}

final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>((ref) {
  return HomeViewModel(
    ref.read(userStateProvider),
    ref.read(timelineRepositoryProvider),
    ref.read(postsCacheProvider),
  );
});
