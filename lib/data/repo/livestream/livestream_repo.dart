import "package:dth_v4/data/models/model.dart";

abstract class LivestreamRepo {
  /// Home-banner status (`GET /livestreams/check`). Returns stream metadata
  /// plus [LivestreamCheckResult.accessLivestream] without requiring a second
  /// gated call to decide subscribe vs open.
  Future<LivestreamCheckResult?> fetchCheck();

  /// Access-gated active livestream (`GET /livestreams`). May throw
  /// `subscription_required` when the viewer is not subscribed.
  Future<Livestream?> fetchActive();

  /// Toggles the authenticated viewer's reaction on a livestream. Returns the
  /// updated stream with fresh `counts.reactions` and `viewer_reacted`.
  Future<Livestream> toggleReaction(String uid);
}
