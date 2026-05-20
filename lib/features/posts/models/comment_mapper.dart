import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/posts/models/comment.dart";
import "package:dth_v4/features/posts/models/post_mapper.dart";

Comment commentFromTimelineComment(TimelineComment c) {
  return Comment(
    uid: c.uid,
    authorName: c.user.fullName,
    username: c.user.username,
    avatarUrl: c.user.avatar,
    body: c.description,
    timeAgo: formatTimeAgo(c.createdAt),
    likeCount: c.counts.reactions,
    replyCount: c.counts.comments,
    shareCount: c.counts.shares,
    viewCount: c.counts.views,
    viewerReacted: c.viewerReacted,
    isReply: c.isReply,
    parentUid: c.parentId,
  );
}

/// Returns [fresh] but with each entry's `viewerReacted` swapped to whatever
/// [lookup] currently has cached for that uid (when present).
///
/// `listComments` / `listReplies` don't reliably echo `viewer_reacted` for
/// the current user — the field is omitted on some payload shapes, which
/// our parser turns into `false`. Taking the server's value verbatim
/// clobbers the reaction state we already confirmed via the toggle
/// endpoint (the only authoritative source). Symptom: like a reply, leave
/// the screen, come back — the heart goes grey while the count stays
/// correct. Apply this when ingesting list responses into the cache.
List<Comment> mergeViewerReacted(
  Iterable<Comment> fresh,
  Comment? Function(String uid) lookup,
) {
  return fresh.map((c) {
    final prev = lookup(c.uid);
    if (prev == null) return c;
    if (prev.viewerReacted == c.viewerReacted) return c;
    return c.copyWith(viewerReacted: prev.viewerReacted);
  }).toList();
}
