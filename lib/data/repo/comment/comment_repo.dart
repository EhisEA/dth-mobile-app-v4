import "package:dth_v4/data/models/model.dart";

/// Sort order for comment / reply lists. Maps to `?sort=latest|oldest`.
enum CommentSort { latest, oldest }

extension CommentSortApiValue on CommentSort {
  String get apiValue {
    switch (this) {
      case CommentSort.latest:
        return "latest";
      case CommentSort.oldest:
        return "oldest";
    }
  }
}

abstract class CommentRepo {
  /// Fetches one page of direct comments. Pass [cursor] (from a prior result's
  /// `nextCursor`) to load the next page.
  Future<PaginatedResult<TimelineComment>> listComments(
    String postUid, {
    String? cursor,
    CommentSort sort = CommentSort.latest,
  });

  /// Fetches one page of replies for a given comment. Pass [cursor] for the
  /// next page.
  Future<PaginatedResult<TimelineComment>> listReplies(
    String commentUid, {
    String? cursor,
    CommentSort sort = CommentSort.latest,
  });

  Future<TimelineComment> createComment(String postUid, String body);
  Future<TimelineComment> createReply(String commentUid, String body);

  /// Toggles the authenticated viewer's reaction on a comment or reply.
  /// Returns the updated comment (fresh `counts.reactions` + `viewer_reacted`).
  Future<TimelineComment> toggleReaction(String commentUid);
}
