import "dart:async";

import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/livestream/view_model/active_livestream_provider.dart";
import "package:dth_v4/features/livestream/view_model/livestreams_cache.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/comment_mapper.dart";
import "package:dth_v4/features/posts/view_model/comments_cache.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Mirrors [PostDetailViewModel] for the active-livestream screen. The
/// stream entity is fetched via [LivestreamRepo] (single GET — there's no
/// per-uid endpoint); comments use [LivestreamCommentRepo]. Comment uids
/// share the global [CommentsCache] since ULIDs don't collide across types.
class LivestreamDetailViewModel extends BaseChangeNotifierViewModel {
  LivestreamDetailViewModel(
    this.uid,
    this._ref,
    this._streamRepo,
    this._commentRepo,
    this._streamsCache,
    this._commentsCache,
  ) {
    _refresh();
    _loadComments();
  }

  final Ref _ref;

  /// Initially the uid handed in from the home pre-check. Once the VM refreshes,
  /// the latest active stream may have a different uid — kept up-to-date by
  /// [_adoptLatestStream] so subsequent comment/react calls hit the right id.
  String uid;

  final LivestreamRepo _streamRepo;
  final LivestreamCommentRepo _commentRepo;
  final LivestreamsCache _streamsCache;
  final CommentsCache _commentsCache;

  Livestream? get livestream => _streamsCache.get(uid);

  List<String> _commentUids = const [];
  List<String> get commentUids => _commentUids;

  bool _commentsLoading = false;
  bool get commentsLoading => _commentsLoading;

  Failure? _commentsError;
  Failure? get commentsError => _commentsError;

  String? _nextCommentCursor;
  bool get hasMoreComments => _nextCommentCursor != null;

  bool _loadingMoreComments = false;
  bool get loadingMoreComments => _loadingMoreComments;

  CommentSort _sort = CommentSort.latest;
  CommentSort get sort => _sort;

  bool _submitting = false;
  bool get submitting => _submitting;

  /// True once the API has reported `data.livestream = null` — UI uses this
  /// to render the empty state instead of a permanent spinner.
  bool _streamEnded = false;
  bool get streamEnded => _streamEnded;

  Future<void> refresh() async {
    await Future.wait([_refresh(), _loadComments(force: true)]);
  }

  Future<void> _refresh() async {
    try {
      if (livestream == null) {
        changeBaseState(const ViewModelState.busy());
      }
      final fresh = await _streamRepo.fetchActive();
      if (fresh == null) {
        _streamEnded = true;
        // Drop the cached check so the next home banner refresh re-fetches
        // instead of showing a stale, ended-stream entry.
        _ref.invalidate(activeLivestreamProvider);
        changeBaseState(const ViewModelState.idle());
        return;
      }
      _adoptLatestStream(fresh);
      _streamEnded = false;
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      if (livestream == null) {
        changeBaseState(ViewModelState.error(e));
      } else {
        notifyListeners();
      }
    }
  }

  void _adoptLatestStream(Livestream fresh) {
    _streamsCache.upsert(fresh);
    if (fresh.uid != uid) {
      // The active stream rotated between the pre-check and this refresh
      // (rare, but possible). Repoint to the new uid so further react /
      // comment calls hit the right resource.
      uid = fresh.uid;
      _commentUids = const [];
      _nextCommentCursor = null;
    }
  }

  int _commentsRequestId = 0;

  Future<void> _loadComments({bool force = false}) async {
    if (_commentsLoading && !force) return;
    final requestId = ++_commentsRequestId;
    _commentsLoading = true;
    _commentsError = null;
    notifyListeners();
    try {
      final result = await _commentRepo.listComments(uid, sort: _sort);
      if (requestId != _commentsRequestId) return;
      final fresh = result.items.map(commentFromTimelineComment);
      final comments = mergeViewerReacted(fresh, _commentsCache.get);
      _commentsCache.upsertAll(comments);
      _commentUids = comments.map((c) => c.uid).toList();
      _nextCommentCursor = result.nextCursor;
    } on ApiFailure catch (e) {
      if (requestId != _commentsRequestId) return;
      _commentsError = e;
    } finally {
      if (requestId == _commentsRequestId) {
        _commentsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryLoadComments() => _loadComments(force: true);

  Future<void> loadMoreComments() async {
    if (!hasMoreComments || _loadingMoreComments || _commentsLoading) return;
    _loadingMoreComments = true;
    notifyListeners();
    try {
      final result = await _commentRepo.listComments(
        uid,
        cursor: _nextCommentCursor,
        sort: _sort,
      );
      final fresh = result.items.map(commentFromTimelineComment);
      final comments = mergeViewerReacted(fresh, _commentsCache.get);
      _commentsCache.upsertAll(comments);
      _commentUids = [..._commentUids, ...comments.map((c) => c.uid)];
      _nextCommentCursor = result.nextCursor;
    } on ApiFailure {
      // Pagination failure swallowed — user can scroll again to retry.
    } finally {
      _loadingMoreComments = false;
      notifyListeners();
    }
  }

  Future<void> setSort(CommentSort sort) async {
    if (sort == _sort) return;
    _sort = sort;
    _commentUids = const [];
    _nextCommentCursor = null;
    notifyListeners();
    await _loadComments(force: true);
  }

  Future<bool> submit(String text) async {
    final body = text.trim();
    if (body.isEmpty || _submitting) return false;
    _submitting = true;
    notifyListeners();
    try {
      final raw = await _commentRepo.createComment(uid, body);
      final comment = commentFromTimelineComment(raw);
      _commentsCache.upsert(comment);
      _commentUids = [comment.uid, ..._commentUids];
      _bumpCommentCount(1);
      _refreshProfileCredits();
      return true;
    } on ApiFailure {
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void _bumpCommentCount(int delta) {
    final current = livestream;
    if (current == null) return;
    final updated = Livestream(
      uid: current.uid,
      title: current.title,
      description: current.description,
      videoLink: current.videoLink,
      videoThumbnail: current.videoThumbnail,
      status: current.status,
      counts: LivestreamCounts(
        comments: current.counts.comments + delta,
        reactions: current.counts.reactions,
        views: current.counts.views,
        shares: current.counts.shares,
      ),
      viewerReacted: current.viewerReacted,
      createdAt: current.createdAt,
    );
    _streamsCache.upsert(updated);
  }

  bool _likePending = false;

  Future<void> toggleLike() async {
    final original = livestream;
    if (original == null || _likePending) return;
    _likePending = true;
    final wasReacted = original.viewerReacted;
    _streamsCache.upsert(
      Livestream(
        uid: original.uid,
        title: original.title,
        description: original.description,
        videoLink: original.videoLink,
        videoThumbnail: original.videoThumbnail,
        status: original.status,
        counts: LivestreamCounts(
          comments: original.counts.comments,
          reactions: original.counts.reactions + (wasReacted ? -1 : 1),
          views: original.counts.views,
          shares: original.counts.shares,
        ),
        viewerReacted: !wasReacted,
        createdAt: original.createdAt,
      ),
    );
    notifyListeners();
    try {
      final fresh = await _streamRepo.toggleReaction(uid);
      _streamsCache.upsert(fresh);
      _refreshProfileCredits();
    } on ApiFailure {
      _streamsCache.upsert(original);
    } finally {
      _likePending = false;
      notifyListeners();
    }
  }

  /// Engagement can award voting credits — pull a fresh profile so chips /
  /// breakdown stay in sync app-wide.
  void _refreshProfileCredits() {
    unawaited(_ref.read(userStateProvider).getUserDetailsFromServer());
  }

  /// Optimistic share bump after a completed share sheet; also refreshes
  /// profile credits.
  void onShared() {
    final current = livestream;
    if (current != null) {
      _streamsCache.upsert(
        Livestream(
          uid: current.uid,
          title: current.title,
          description: current.description,
          videoLink: current.videoLink,
          videoThumbnail: current.videoThumbnail,
          status: current.status,
          counts: LivestreamCounts(
            comments: current.counts.comments,
            reactions: current.counts.reactions,
            views: current.counts.views,
            shares: current.counts.shares + 1,
          ),
          viewerReacted: current.viewerReacted,
          createdAt: current.createdAt,
        ),
      );
      notifyListeners();
    }
    _refreshProfileCredits();
  }

  final Set<String> _commentLikesPending = {};

  Future<void> toggleCommentLike(Comment comment) async {
    if (_commentLikesPending.contains(comment.uid)) return;
    _commentLikesPending.add(comment.uid);
    final wasReacted = comment.viewerReacted;
    _commentsCache.upsert(
      comment.copyWith(
        viewerReacted: !wasReacted,
        likeCount: comment.likeCount + (wasReacted ? -1 : 1),
      ),
    );
    notifyListeners();
    try {
      final raw = await _commentRepo.toggleReaction(comment.uid);
      final fresh = commentFromTimelineComment(raw);
      final current = _commentsCache.get(comment.uid) ?? comment;
      _commentsCache.upsert(
        current.copyWith(
          likeCount: fresh.likeCount,
          replyCount: fresh.replyCount,
        ),
      );
    } on ApiFailure {
      _commentsCache.upsert(comment);
    } finally {
      _commentLikesPending.remove(comment.uid);
      notifyListeners();
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}

final livestreamDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<LivestreamDetailViewModel, String>((ref, uid) {
      return LivestreamDetailViewModel(
        uid,
        ref,
        ref.read(livestreamRepositoryProvider),
        ref.read(livestreamCommentRepositoryProvider),
        ref.read(livestreamsCacheProvider),
        ref.read(commentsCacheProvider),
      );
    });
