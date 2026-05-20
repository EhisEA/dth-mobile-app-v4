import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/comment_mapper.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/features/posts/models/post_mapper.dart";
import "package:dth_v4/features/posts/view_model/comments_cache.dart";
import "package:dth_v4/features/posts/view_model/posts_cache.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class PostDetailViewModel extends BaseChangeNotifierViewModel {
  PostDetailViewModel(
    this.uid,
    this._postRepo,
    this._commentRepo,
    this._postsCache,
    this._commentsCache,
  ) {
    _refresh();
    _loadComments();
  }

  final String uid;
  final PostRepo _postRepo;
  final CommentRepo _commentRepo;
  final PostsCache _postsCache;
  final CommentsCache _commentsCache;

  Post? get post => _postsCache.get(uid);

  /// Order-only. The actual `Comment` objects live in [CommentsCache] — the
  /// view derives the list by mapping these uids through `cache.get(uid)`.
  /// Keeps the cache as single source of truth so a like toggle on the
  /// thread screen reflects here automatically.
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

  Future<void> refresh() async {
    // Pull-to-refresh wants fresh data for both — bypass the in-flight guard
    // on comments. The request-id check inside `_loadComments` discards any
    // earlier in-flight result so only the latest reload wins.
    await Future.wait([_refresh(), _loadComments(force: true)]);
  }

  Future<void> _refresh() async {
    try {
      if (post == null) {
        changeBaseState(const ViewModelState.busy());
      }
      final raw = await _postRepo.fetchPost(uid);
      _postsCache.upsert(postFromTimelinePost(raw));
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      if (post == null) {
        changeBaseState(ViewModelState.error(e));
      } else {
        notifyListeners();
      }
    }
  }

  // Bumped on every comments-list fetch; lets us discard a stale result if a
  // newer fetch (e.g. sort change, pull-to-refresh) was kicked off mid-flight.
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
      // listComments doesn't reliably return `viewer_reacted` — keep the
      // cached reaction state (set by the toggle endpoint, the only
      // authoritative source) so navigating back to this screen doesn't
      // flip a liked comment back to grey.
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
      // Pagination failure — list just doesn't advance; user can scroll
      // again to retry.
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
    // Force-load so any in-flight fetch with the old sort gets discarded by
    // the request-id check rather than overwriting our cleared list.
    await _loadComments(force: true);
  }

  /// Posts a top-level comment. Returns true on success so the composer can
  /// clear its field.
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
      _bumpPostCommentCount(1);
      return true;
    } on ApiFailure {
      // Comment didn't appear in the list AND the composer didn't clear —
      // both signal failure to the user without needing a toast.
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void _bumpPostCommentCount(int delta) {
    final current = post;
    if (current == null) return;
    _postsCache.upsert(
      current.copyWith(commentCount: current.commentCount + delta),
    );
  }

  /// Optimistic post like/unlike. Cache is flipped immediately; the server
  /// response then settles the canonical counts. Rolls back + toasts on failure.
  Future<void> togglePostLike() async {
    final original = post;
    if (original == null || _postLikePending) return;
    _postLikePending = true;
    final wasReacted = original.viewerReacted;
    _postsCache.upsert(
      original.copyWith(
        viewerReacted: !wasReacted,
        likeCount: original.likeCount + (wasReacted ? -1 : 1),
      ),
    );
    notifyListeners();
    try {
      final raw = await _postRepo.toggleReaction(uid);
      _postsCache.upsert(postFromTimelinePost(raw));
    } on ApiFailure {
      // Optimistic rollback above is the user-visible signal — no toast.
      _postsCache.upsert(original);
    } finally {
      _postLikePending = false;
      notifyListeners();
    }
  }

  bool _postLikePending = false;

  /// Optimistic comment like. Updates pass through [CommentsCache] so any
  /// other surface watching the same comment (e.g. the thread screen) reacts
  /// automatically.
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
      // Trust the server for aggregate counts only — the toggle endpoint
      // doesn't always echo `viewer_reacted`, and our parser treats missing
      // as `false`. Overriding the optimistic flip would flicker the heart
      // back to grey while the count stayed bumped.
      final current = _commentsCache.get(comment.uid) ?? comment;
      _commentsCache.upsert(
        current.copyWith(
          likeCount: fresh.likeCount,
          replyCount: fresh.replyCount,
        ),
      );
    } on ApiFailure {
      // Optimistic rollback above is the user-visible signal — no toast.
      _commentsCache.upsert(comment);
    } finally {
      _commentLikesPending.remove(comment.uid);
      notifyListeners();
    }
  }

  final Set<String> _commentLikesPending = {};

  // autoDispose.family disposes this VM when the user navigates back. Pending
  // awaits (`_refresh`, `_loadComments`, etc.) can resume *after* dispose and
  // try to call `notifyListeners()` — which throws on a disposed
  // ChangeNotifier. Guarding here makes every post-await notify a no-op.
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

final postDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<PostDetailViewModel, String>((ref, uid) {
      return PostDetailViewModel(
        uid,
        ref.read(postRepositoryProvider),
        ref.read(commentRepositoryProvider),
        ref.read(postsCacheProvider),
        ref.read(commentsCacheProvider),
      );
    });
