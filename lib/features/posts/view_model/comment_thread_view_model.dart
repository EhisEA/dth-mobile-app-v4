import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/comment_mapper.dart";
import "package:dth_v4/features/posts/view_model/comments_cache.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Drives the comment thread screen — a parent comment shown as a header with
/// its replies listed flat below. Reads the parent comment from
/// [CommentsCache] (populated by the post detail screen on the way in) so
/// like-toggles stay coherent across both surfaces.
class CommentThreadViewModel extends BaseChangeNotifierViewModel {
  CommentThreadViewModel(
    this.commentUid,
    this._commentRepo,
    this._commentsCache,
  ) {
    _loadReplies();
  }

  final String commentUid;
  final CommentRepo _commentRepo;
  final CommentsCache _commentsCache;

  Comment? get parent => _commentsCache.get(commentUid);

  List<String> _replyUids = const [];
  List<String> get replyUids => _replyUids;

  bool _repliesLoading = false;
  bool get repliesLoading => _repliesLoading;

  Failure? _repliesError;
  Failure? get repliesError => _repliesError;

  String? _nextCursor;
  bool get hasMore => _nextCursor != null;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  CommentSort _sort = CommentSort.latest;
  CommentSort get sort => _sort;

  bool _submitting = false;
  bool get submitting => _submitting;

  Future<void> refresh() => _loadReplies();

  Future<void> _loadReplies() async {
    _repliesLoading = true;
    _repliesError = null;
    notifyListeners();
    try {
      final result = await _commentRepo.listReplies(commentUid, sort: _sort);
      final replies = result.items.map(commentFromTimelineComment).toList();
      _commentsCache.upsertAll(replies);
      _replyUids = replies.map((r) => r.uid).toList();
      _nextCursor = result.nextCursor;
    } on ApiFailure catch (e) {
      _repliesError = e;
    } finally {
      _repliesLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => _loadReplies();

  Future<void> loadMore() async {
    if (!hasMore || _loadingMore || _repliesLoading) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await _commentRepo.listReplies(
        commentUid,
        cursor: _nextCursor,
        sort: _sort,
      );
      final replies = result.items.map(commentFromTimelineComment).toList();
      _commentsCache.upsertAll(replies);
      _replyUids = [..._replyUids, ...replies.map((r) => r.uid)];
      _nextCursor = result.nextCursor;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Load more");
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setSort(CommentSort sort) async {
    if (sort == _sort) return;
    _sort = sort;
    _replyUids = const [];
    _nextCursor = null;
    notifyListeners();
    await _loadReplies();
  }

  /// Posts a reply to the parent comment. Returns true if accepted so the
  /// composer can clear its field.
  Future<bool> submit(String text) async {
    final body = text.trim();
    if (body.isEmpty || _submitting) return false;
    _submitting = true;
    notifyListeners();
    try {
      final raw = await _commentRepo.createReply(commentUid, body);
      final reply = commentFromTimelineComment(raw);
      _commentsCache.upsert(reply);
      _replyUids = [reply.uid, ..._replyUids];
      _bumpParentReplyCount(1);
      return true;
    } on ApiFailure catch (e) {
      DthFlushBar.instance.showError(message: e.message, title: "Failed");
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void _bumpParentReplyCount(int delta) {
    final current = parent;
    if (current == null) return;
    _commentsCache.upsert(
      current.copyWith(replyCount: current.replyCount + delta),
    );
  }

  /// Optimistic like on the parent comment. Routes through the cache so the
  /// post-detail screen reflects the new state when the user pops back.
  Future<void> toggleParentLike() async {
    final current = parent;
    if (current == null) return;
    await _toggleLike(current);
  }

  /// Optimistic like on a reply.
  Future<void> toggleReplyLike(Comment reply) => _toggleLike(reply);

  Future<void> _toggleLike(Comment c) async {
    if (_likesPending.contains(c.uid)) return;
    _likesPending.add(c.uid);
    final wasReacted = c.viewerReacted;
    _commentsCache.upsert(
      c.copyWith(
        viewerReacted: !wasReacted,
        likeCount: c.likeCount + (wasReacted ? -1 : 1),
      ),
    );
    notifyListeners();
    try {
      final raw = await _commentRepo.toggleReaction(c.uid);
      final fresh = commentFromTimelineComment(raw);
      _commentsCache.upsert(
        c.copyWith(
          viewerReacted: fresh.viewerReacted,
          likeCount: fresh.likeCount,
          replyCount: fresh.replyCount,
        ),
      );
    } on ApiFailure catch (e) {
      _commentsCache.upsert(c);
      DthFlushBar.instance.showError(message: e.message, title: "Like");
    } finally {
      _likesPending.remove(c.uid);
      notifyListeners();
    }
  }

  final Set<String> _likesPending = {};
}

final commentThreadViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<CommentThreadViewModel, String>((ref, commentUid) {
      return CommentThreadViewModel(
        commentUid,
        ref.read(commentRepositoryProvider),
        ref.read(commentsCacheProvider),
      );
    });
