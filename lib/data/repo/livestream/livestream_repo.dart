import "package:dth_v4/data/models/model.dart";

abstract class LivestreamRepo {
  /// Fetches the currently active livestream. Returns `null` when there is
  /// no active stream — the API still returns `200` with `data: { livestream: null }`.
  Future<Livestream?> fetchActive();

  /// Toggles the authenticated viewer's reaction on a livestream. Returns the
  /// updated stream with fresh `counts.reactions` and `viewer_reacted`.
  Future<Livestream> toggleReaction(String uid);
}
