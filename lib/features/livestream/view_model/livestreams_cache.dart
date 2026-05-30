import "package:dth_v4/data/models/model.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// In-memory cache of [Livestream] entities keyed by uid. Mirrors
/// `PostsCache` so the same like-toggle / count-bump patterns work in
/// [LivestreamDetailViewModel] without bespoke plumbing.
class LivestreamsCache extends ChangeNotifier {
  final Map<String, Livestream> _byUid = {};

  Livestream? get(String uid) => _byUid[uid];

  void upsert(Livestream stream) {
    _byUid[stream.uid] = stream;
    notifyListeners();
  }
}

final livestreamsCacheProvider = ChangeNotifierProvider<LivestreamsCache>((
  ref,
) {
  return LivestreamsCache();
});
