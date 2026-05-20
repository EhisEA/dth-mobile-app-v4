import "package:dth_v4/data/data.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Shared in-memory cache of reels keyed by uid. Home feed (timeline reels
/// row), search trending reels, and the reel viewer all read/write this so
/// any mutation (like flips, count bumps) propagates everywhere without
/// prop drilling — mirrors [PostsCache].
class ReelsCache extends ChangeNotifier {
  final Map<String, TimelineReel> _byUid = {};

  /// Uids in the order returned by the last [upsertAll] (timeline reels API).
  List<String> _orderUids = const [];

  TimelineReel? get(String uid) => _byUid[uid];

  /// Reels from the last full list sync, in API order (e.g. home timeline row).
  List<TimelineReel> get orderedReels => _orderUids
      .map((uid) => _byUid[uid])
      .whereType<TimelineReel>()
      .toList(growable: false);

  void upsert(TimelineReel reel) {
    _byUid[reel.uid] = reel;
    notifyListeners();
  }

  void upsertAll(Iterable<TimelineReel> reels) {
    final list = reels.toList();
    _orderUids = list.map((r) => r.uid).toList(growable: false);
    for (final r in list) {
      _byUid[r.uid] = r;
    }
    notifyListeners();
  }
}

final reelsCacheProvider = ChangeNotifierProvider<ReelsCache>((ref) {
  return ReelsCache();
});
