import "package:dth_v4/features/posts/models/post.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Shared in-memory cache of posts keyed by uid. Home feed and post detail
/// both read/write this so any mutation (count bumps, future like/share)
/// propagates everywhere without prop drilling.
class PostsCache extends ChangeNotifier {
  final Map<String, Post> _byUid = {};

  Post? get(String uid) => _byUid[uid];

  void upsert(Post post) {
    _byUid[post.uid] = post;
    notifyListeners();
  }

  void upsertAll(Iterable<Post> posts) {
    var changed = false;
    for (final p in posts) {
      _byUid[p.uid] = p;
      changed = true;
    }
    if (changed) notifyListeners();
  }
}

final postsCacheProvider = ChangeNotifierProvider<PostsCache>((ref) {
  return PostsCache();
});
