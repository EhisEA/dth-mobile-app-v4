import "package:dth_v4/features/posts/models/comment.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Shared in-memory cache of comments (and replies — same shape) keyed by uid.
/// Post detail and the comment thread screen both read/write this so a like
/// toggle or count bump on either screen propagates without prop drilling.
class CommentsCache extends ChangeNotifier {
  final Map<String, Comment> _byUid = {};

  Comment? get(String uid) => _byUid[uid];

  void upsert(Comment comment) {
    _byUid[comment.uid] = comment;
    notifyListeners();
  }

  void upsertAll(Iterable<Comment> comments) {
    var changed = false;
    for (final c in comments) {
      _byUid[c.uid] = c;
      changed = true;
    }
    if (changed) notifyListeners();
  }
}

final commentsCacheProvider = ChangeNotifierProvider<CommentsCache>((ref) {
  return CommentsCache();
});
