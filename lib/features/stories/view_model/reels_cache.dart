import "package:dth_v4/data/data.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Shared in-memory cache of reels keyed by uid. Home feed (timeline reels
/// row), search trending reels, and the reel viewer all read/write this so
/// any mutation (like flips, count bumps) propagates everywhere without
/// prop drilling — mirrors [PostsCache].
class ReelsCache extends ChangeNotifier {
  final Map<String, TimelineReel> _byUid = {};

  TimelineReel? get(String uid) => _byUid[uid];

  void upsert(TimelineReel reel) {
    _byUid[reel.uid] = reel;
    notifyListeners();
  }

  void upsertAll(Iterable<TimelineReel> reels) {
    var changed = false;
    for (final r in reels) {
      _byUid[r.uid] = r;
      changed = true;
    }
    if (changed) notifyListeners();
  }
}

final reelsCacheProvider = ChangeNotifierProvider<ReelsCache>((ref) {
  return ReelsCache();
});
