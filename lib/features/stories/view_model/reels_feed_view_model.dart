import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/stories/view_model/reels_cache.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Owns the swipe order + cursor pagination for the vertical reel pager
/// ([StoriesView]). Reel *data* lives in [ReelsCache]; this VM only owns the
/// ordered list of uids the user can swipe through and the pagination cursor.
///
/// Seeds its order from [ReelsCache] so entering from home/search has neighbours
/// to swipe to on the very first frame (no network wait). The opened reel is
/// guaranteed present — prepended when the cache is cold (deep-link entry), so
/// the linked reel is page 0 with the feed below it.
class ReelsFeedViewModel extends ChangeNotifier {
  ReelsFeedViewModel(this._timelineRepo, this._reelsCache, this._initialUid) {
    final seed = _reelsCache.orderedReels
        .map((r) => r.uid)
        .toList(growable: false);
    if (_initialUid.isNotEmpty && !seed.contains(_initialUid)) {
      _uids = [_initialUid, ...seed];
    } else {
      _uids = seed;
    }
  }

  static const _logger = AppLogger(ReelsFeedViewModel);

  final TimelineRepo _timelineRepo;
  final ReelsCache _reelsCache;
  final String _initialUid;

  List<String> _uids = const [];
  List<String> get uids => _uids;

  String? _nextCursor;
  bool _loadedFirstPage = false;
  bool _loadingFirst = false;
  bool _loadingMore = false;

  bool get loadingMore => _loadingMore;

  /// True until the first page has resolved, then tracks the cursor. Drives
  /// whether [loadMore] does anything.
  bool get hasMore => !_loadedFirstPage || _nextCursor != null;

  /// Loads the first feed page once. For home/search entry this mainly supplies
  /// the pagination cursor (the seeded order is preserved). For deep links it
  /// fills the pager below the opened reel.
  Future<void> ensureLoaded() async {
    if (_loadedFirstPage || _loadingFirst) return;
    _loadingFirst = true;
    try {
      final result = await _timelineRepo.fetchTimelineReels();
      _reelsCache.cacheAll(result.items);
      _appendUnseen(
        result.items.map((r) => r.uid).toList(growable: false),
        result.nextCursor,
      );
    } on ApiFailure catch (e) {
      // Pager still works on whatever we seeded — just no pagination.
      _logger.w("Reel feed first page failed: ${e.message}");
    } finally {
      _loadingFirst = false;
      _loadedFirstPage = true;
      notifyListeners();
    }
  }

  /// Fetches the next cursor page and appends unseen reels. Called as the user
  /// nears the end of the loaded list.
  Future<void> loadMore() async {
    if (_loadingMore || _nextCursor == null) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await _timelineRepo.fetchTimelineReels(cursor: _nextCursor);
      _reelsCache.cacheAll(result.items);
      _appendUnseen(
        result.items.map((r) => r.uid).toList(growable: false),
        result.nextCursor,
      );
    } on ApiFailure catch (e) {
      // Pagination just stalls; existing pages stay swipeable.
      _logger.w("Reel feed page failed: ${e.message}");
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Preserves the current order (the seed / opened reel / already-paged
  /// reels) and appends any uids we haven't shown yet. Keeping existing indices
  /// stable means the [PageController] never jumps under the user.
  void _appendUnseen(List<String> pageUids, String? cursor) {
    _nextCursor = cursor;
    if (_uids.isEmpty) {
      _uids = pageUids;
      return;
    }
    final seen = _uids.toSet();
    final fresh = pageUids.where((u) => !seen.contains(u));
    _uids = [..._uids, ...fresh];
  }
}

final reelsFeedViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<ReelsFeedViewModel, String>((ref, initialUid) {
      return ReelsFeedViewModel(
        ref.read(timelineRepositoryProvider),
        ref.read(reelsCacheProvider),
        initialUid,
      );
    });
