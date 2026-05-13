import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/data/repo/comment/comment_repo.dart" show CommentSort;

/// Reel-scoped comment endpoints. Mirrors [CommentRepo]'s shape but talks to
/// `/timeline-reels/...`. Reuses [CommentSort] from the post comment repo
/// since the `?sort=` query parameter is identical.
abstract class ReelCommentRepo {
  /// Fetches the canonical [TimelineReel] for the given uid.
  Future<TimelineReel> fetchReel(String reelUid);

  /// Fetches one page of direct comments on a reel.
  Future<PaginatedResult<TimelineComment>> listComments(
    String reelUid, {
    String? cursor,
    CommentSort sort = CommentSort.latest,
  });

  /// Posts a new top-level comment to a reel.
  Future<TimelineComment> createComment(String reelUid, String body);

  /// Toggles the viewer's reaction on a reel comment.
  Future<TimelineComment> toggleCommentReaction(String commentUid);

  /// Toggles the viewer's reaction on the reel itself; returns the updated
  /// reel (with fresh `counts.reactions` + `viewer_reacted`).
  Future<TimelineReel> toggleReelReaction(String reelUid);
}
