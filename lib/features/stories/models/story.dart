import "package:flutter/foundation.dart";

/// UI projection for the home / search stories bar. Only carries what the
/// tile needs (uid, poster, label) — full reel detail is sourced from
/// [ReelsCache] / the reel API when the user opens [StoriesView].
@immutable
class Story {
  const Story({
    required this.uid,
    required this.imageUrl,
    required this.label,
  });

  final String uid;
  final String imageUrl;
  final String label;
}
