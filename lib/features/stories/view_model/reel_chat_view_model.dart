import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/comment_mapper.dart";
import "package:dth_v4/features/stories/view_model/reels_cache.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Drives the reel viewer — fetches the reel detail (so we never trust nav
/// args for the meta payload), the comment list, posts new comments, and
/// toggles per-comment + reel-level likes.
///
/// State machine layout:
/// - `baseState` → reel detail fetch (the primary content).
/// - `getState("comments")` → comment list fetch.
/// - `getState("loadMore")`, `getState("submit")`, `getState("reelLike")`,
///   `getState("like:<commentUid>")` → sub-operations.
/// All notifications go through the base class's disposal-safe `_notify()`,
/// so an in-flight await resolving on an `autoDispose`-killed VM no-ops.
class ReelChatViewModel extends BaseChangeNotifierViewModel {
  ReelChatViewModel(this.reelUid, this._reelCommentRepo, this._reelsCache) {
    if (reelUid.isNotEmpty) {
      _fetchReel();
      _loadComments();
    }
  }

  static const String _commentsKey = "comments";
  static const String _submitKey = "submit";
  static const String _loadMoreKey = "loadMore";
  static const String _reelLikeKey = "reelLike";
  static String _likeKey(String commentUid) => "like:$commentUid";

  final String reelUid;
  final ReelCommentRepo _reelCommentRepo;
  final ReelsCache _reelsCache;

  /// Canonical reel — sourced from [ReelsCache] so listing screens stay in
  /// sync with whatever this VM mutates (likes, future count bumps).
  TimelineReel? get reel => _reelsCache.get(reelUid);

  List<Comment> _comments = const [];
  List<Comment> get comments => _comments;

  String? _nextCursor;
  bool get hasMore => _nextCursor != null;

  /// UI-friendly mirrors of [baseState] / keyed sub-states.
  bool get loading => isBaseBusy;

  Failure? get error =>
      baseState.maybeWhen<Failure?>(error: (f) => f, orElse: () => null);

  bool get commentsLoading => _isBusy(_commentsKey);
  bool get submitting => _isBusy(_submitKey);
  bool get loadingMore => _isBusy(_loadMoreKey);

  Failure? get commentsError =>
      getState(_commentsKey)?.maybeWhen<Failure?>(
        error: (f) => f,
        orElse: () => null,
      );

  /// Re-fetches both the reel and the first page of comments.
  Future<void> refresh() async {
    await Future.wait([_fetchReel(), _loadComments()]);
  }

  Future<void> _fetchReel() async {
    // Only block on the spinner the first time — if the cache already has
    // this reel (because we're coming from the home feed), keep showing it
    // while we refresh in the background.
    if (reel == null) {
      changeBaseState(const ViewModelState.busy());
    }
    try {
      final fresh = await _reelCommentRepo.fetchReel(reelUid);
      _reelsCache.upsert(fresh);
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      if (reel == null) {
        changeBaseState(ViewModelState.error(e));
      } else {
        // Reel is already cached; treat the refresh failure as non-fatal.
        DthFlushBar.instance.showError(message: e.message, title: "Reel");
      }
    }
  }

  Future<void> _loadComments() async {
    setState(_commentsKey, const ViewModelState.busy());
    try {
      final result = await _reelCommentRepo.listComments(reelUid);
      _comments = result.items.map(commentFromTimelineComment).toList();
      _nextCursor = result.nextCursor;
      setState(_commentsKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      setState(_commentsKey, ViewModelState.error(e));
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || commentsLoading) return;
    setState(_loadMoreKey, const ViewModelState.busy());
    try {
      final result = await _reelCommentRepo.listComments(
        reelUid,
        cursor: _nextCursor,
      );
      _comments = [
        ..._comments,
        ...result.items.map(commentFromTimelineComment),
      ];
      _nextCursor = result.nextCursor;
      setState(_loadMoreKey, const ViewModelState.idle());
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Load more");
      setState(_loadMoreKey, ViewModelState.error(e));
    }
  }

  /// Posts a new top-level comment on the reel. Returns true on success so the
  /// composer can clear its field.
  Future<bool> submit(String text) async {
    final body = text.trim();
    if (body.isEmpty || submitting || reelUid.isEmpty) return false;
    setState(_submitKey, const ViewModelState.busy());
    try {
      final raw = await _reelCommentRepo.createComment(reelUid, body);
      final comment = commentFromTimelineComment(raw);
      _comments = [comment, ..._comments];
      setState(_submitKey, const ViewModelState.idle());
      return true;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Comment");
      setState(_submitKey, ViewModelState.error(e));
      return false;
    }
  }

  /// Optimistic like on a comment; rolls back on API failure. Per-comment
  /// keyed state both dedups concurrent taps and drives the notify.
  Future<void> toggleCommentLike(Comment c) async {
    final key = _likeKey(c.uid);
    if (hasState(key)) return;

    final wasReacted = c.viewerReacted;
    _replace(
      c.copyWith(
        viewerReacted: !wasReacted,
        likeCount: c.likeCount + (wasReacted ? -1 : 1),
      ),
    );
    setState(key, const ViewModelState.busy());

    try {
      final raw = await _reelCommentRepo.toggleCommentReaction(c.uid);
      final fresh = commentFromTimelineComment(raw);
      _replace(
        c.copyWith(
          viewerReacted: fresh.viewerReacted,
          likeCount: fresh.likeCount,
          replyCount: fresh.replyCount,
        ),
      );
    } on ApiFailure catch (e) {
      _replace(c);
      DthFlushBar.instance.showError(message: e.message, title: "Like");
    } finally {
      removeState(key);
    }
  }

  /// Optimistic toggle on the reel itself. Writes through [ReelsCache] so the
  /// home feed reflects the new state when the user pops back.
  Future<void> toggleReelLike() async {
    final current = reel;
    if (reelUid.isEmpty || current == null || hasState(_reelLikeKey)) return;

    final wasLiked = current.viewerReacted;
    _reelsCache.upsert(
      _copyReelWithLike(
        current,
        viewerReacted: !wasLiked,
        reactions: current.counts.reactions + (wasLiked ? -1 : 1),
      ),
    );
    setState(_reelLikeKey, const ViewModelState.busy());

    try {
      final updated = await _reelCommentRepo.toggleReelReaction(reelUid);
      _reelsCache.upsert(updated);
    } on ApiFailure catch (e) {
      _reelsCache.upsert(current);
      DthFlushBar.instance.showError(message: e.message, title: "Like");
    } finally {
      removeState(_reelLikeKey);
    }
  }

  /// `TimelineReel` is immutable + has no `copyWith`, so build the new
  /// instance by hand. Keep this in one place so optimistic + rollback share
  /// the shape.
  TimelineReel _copyReelWithLike(
    TimelineReel base, {
    required bool viewerReacted,
    required int reactions,
  }) {
    return TimelineReel(
      uid: base.uid,
      title: base.title,
      description: base.description,
      videoType: base.videoType,
      videoLink: base.videoLink,
      videoThumbnail: base.videoThumbnail,
      media: base.media,
      counts: TimelinePostCounts(
        comments: base.counts.comments,
        reactions: reactions,
        views: base.counts.views,
        shares: base.counts.shares,
      ),
      createdAt: base.createdAt,
      viewerReacted: viewerReacted,
    );
  }

  /// Pure mutation — no notify. Callers pair this with a `setState` /
  /// `removeState` so the flush is disposal-safe.
  void _replace(Comment updated) {
    final i = _comments.indexWhere((x) => x.uid == updated.uid);
    if (i < 0) return;
    final next = [..._comments];
    next[i] = updated;
    _comments = next;
  }

  bool _isBusy(String key) =>
      getState(key)?.maybeWhen<bool>(
        busy: () => true,
        orElse: () => false,
      ) ??
      false;
}

final reelChatViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<ReelChatViewModel, String>((ref, reelUid) {
      return ReelChatViewModel(
        reelUid,
        ref.read(reelCommentRepositoryProvider),
        ref.read(reelsCacheProvider),
      );
    });
