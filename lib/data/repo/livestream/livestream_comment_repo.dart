import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/data/repo/comment/comment_repo.dart";

/// Livestream comments share [TimelineComment] / [CommentSort] with the
/// timeline-post comments — only the underlying endpoints differ. The API
/// does not currently expose replies for livestream comments, so this
/// interface is intentionally smaller than [CommentRepo].
abstract class LivestreamCommentRepo {
  Future<PaginatedResult<TimelineComment>> listComments(
    String livestreamUid, {
    String? cursor,
    CommentSort sort = CommentSort.latest,
  });

  Future<TimelineComment> createComment(String livestreamUid, String body);

  /// Toggles the authenticated viewer's reaction on a livestream comment.
  /// Returns the updated comment.
  Future<TimelineComment> toggleReaction(String commentUid);
}
