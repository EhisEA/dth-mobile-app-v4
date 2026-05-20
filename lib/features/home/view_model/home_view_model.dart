import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/posts/models/post_mapper.dart";
import "package:dth_v4/features/posts/view_model/posts_cache.dart";
import "package:dth_v4/features/stories/models/story.dart";
import "package:dth_v4/features/stories/models/timeline_reel_story_mapper.dart";
import "package:dth_v4/features/stories/view_model/reels_cache.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class HomeViewModel extends BaseChangeNotifierViewModel {
  HomeViewModel(
    this.userState,
    this._timelineRepo,
    this._postRepo,
    this._postsCache,
    this._reelsCache,
  );

  final UserState userState;
  final TimelineRepo _timelineRepo;
  final PostRepo _postRepo;
  final PostsCache _postsCache;
  final ReelsCache _reelsCache;

  final Set<String> _likePending = <String>{};

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
        _reelsCache.upsertAll(reelsResult.items);
        _stories = reelsResult.items.map(storyFromTimelineReel).toList();
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
    } on ApiFailure {
      // Pull-to-refresh failure — user can pull again. The existing list
      // stays on screen unchanged, so they can see it didn't update.
      notifyListeners();
      return;
    }

    try {
      final reelsResult = await _timelineRepo.fetchTimelineReels();
      _reelsCache.upsertAll(reelsResult.items);
      _stories = reelsResult.items.map(storyFromTimelineReel).toList();
    } on ApiFailure {
      // Reels are a secondary strip — silent on refresh failure.
    }

    notifyListeners();
  }

  /// Optimistic like/unlike for any post in the feed. Mirrors the detail
  /// screen's flow — flip the cache immediately, await the server response
  /// for canonical counts, roll back + toast on failure.
  Future<void> togglePostLike(String uid) async {
    if (_likePending.contains(uid)) return;
    final original = _postsCache.get(uid);
    if (original == null) return;
    _likePending.add(uid);
    final wasReacted = original.viewerReacted;
    _postsCache.upsert(
      original.copyWith(
        viewerReacted: !wasReacted,
        likeCount: original.likeCount + (wasReacted ? -1 : 1),
      ),
    );
    try {
      final raw = await _postRepo.toggleReaction(uid);
      _postsCache.upsert(postFromTimelinePost(raw));
    } on ApiFailure {
      // Optimistic rollback above is the user-visible signal — no toast.
      _postsCache.upsert(original);
    } finally {
      _likePending.remove(uid);
    }
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
    } on ApiFailure {
      // Pagination failure — the loading spinner just clears, list doesn't
      // advance. User can scroll again to retry.
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }
}

final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>((ref) {
  return HomeViewModel(
    ref.read(userStateProvider),
    ref.read(timelineRepositoryProvider),
    ref.read(postRepositoryProvider),
    ref.read(postsCacheProvider),
    ref.read(reelsCacheProvider),
  );
});
