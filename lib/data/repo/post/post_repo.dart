import "package:dth_v4/data/models/model.dart";

abstract class PostRepo {
  Future<TimelinePost> fetchPost(String uid);

  /// Toggles the authenticated viewer's reaction on a post. Returns the
  /// updated post (with fresh `counts.reactions` and `viewer_reacted`).
  Future<TimelinePost> toggleReaction(String uid);
}
