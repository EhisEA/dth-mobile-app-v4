import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/comment_mapper.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/features/posts/models/post_mapper.dart";
import "package:dth_v4/features/posts/view_model/comments_cache.dart";
import "package:dth_v4/features/posts/view_model/posts_cache.dart";
import "package:dth_v4/widgets/widgets.dart";
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
    await Future.wait([_refresh(), _loadComments()]);
  }

  Future<void> _refresh() async {
    try {
      if (post == null) {
        changeBaseState(const ViewModelState.busy());
      }
      final raw = await _postRepo.fetchPost(uid);
      _postsCache.upsert(postFromTimelinePost(raw));
      changeBaseState(const ViewModelState.idle());
      // Kick off comments after we have the post (idempotent if already loaded).
      if (_commentUids.isEmpty && !_commentsLoading) {
        await _loadComments();
      }
    } on ApiFailure catch (e) {
      if (post == null) {
        changeBaseState(ViewModelState.error(e));
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> _loadComments() async {
    _commentsLoading = true;
    _commentsError = null;
    notifyListeners();
    try {
      final result = await _commentRepo.listComments(uid, sort: _sort);
      final comments = result.items.map(commentFromTimelineComment).toList();
      _commentsCache.upsertAll(comments);
      _commentUids = comments.map((c) => c.uid).toList();
      _nextCommentCursor = result.nextCursor;
    } on ApiFailure catch (e) {
      _commentsError = e;
    } finally {
      _commentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryLoadComments() => _loadComments();

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
      final comments = result.items.map(commentFromTimelineComment).toList();
      _commentsCache.upsertAll(comments);
      _commentUids = [..._commentUids, ...comments.map((c) => c.uid)];
      _nextCommentCursor = result.nextCursor;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Load more");
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
    await _loadComments();
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
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Failed");
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
    } on ApiFailure catch (e) {
      _postsCache.upsert(original);
      DthFlushBar.instance.showError(message: e.message, title: "Like");
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
      _commentsCache.upsert(
        comment.copyWith(
          viewerReacted: fresh.viewerReacted,
          likeCount: fresh.likeCount,
          replyCount: fresh.replyCount,
        ),
      );
    } on ApiFailure catch (e) {
      _commentsCache.upsert(comment);
      DthFlushBar.instance.showError(message: e.message, title: "Like");
    } finally {
      _commentLikesPending.remove(comment.uid);
      notifyListeners();
    }
  }

  final Set<String> _commentLikesPending = {};
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
