import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

/// Shared [Hero] tags + wrappers so the same media animates across the
/// feed [PostCard] → post detail → fullscreen viewer transitions.
///
/// Tags are namespaced by a per-post [prefix] (the post uid) so two posts that
/// happen to share a media URL never collide within a single screen — Flutter
/// asserts when two heroes share a tag in the same subtree. This relies on a
/// given post being rendered at most once per screen, which holds for the feed,
/// the detail screen and the viewer.

/// Hero tag for the post image at [url] within the post identified by [prefix].
String postImageHeroTag(String prefix, String url) => "post-image-$prefix-$url";

/// Hero tag for a post's video block within the post identified by [prefix].
String postVideoHeroTag(String prefix) => "post-video-$prefix";

/// Wraps an image in a [Hero] whose in-flight shuttle always paints the photo
/// with [BoxFit.cover]. The image is already cached by the time these
/// transitions run, so the shuttle resolves instantly (no placeholder flash)
/// and the photo reads as smoothly enlarging — even when source and destination
/// paint it with different fits (e.g. cover on the card, contain in the
/// fullscreen viewer).
class PostImageHero extends StatelessWidget {
  const PostImageHero({
    super.key,
    required this.tag,
    required this.url,
    required this.child,
  });

  final String tag;
  final String url;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (_, _, _, _, _) =>
          CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
      child: child,
    );
  }
}

/// Wraps a video block in a [Hero] whose in-flight shuttle paints the cached
/// [thumbnailUrl]. Using the thumbnail (rather than the live player) for the
/// flight keeps the transition smooth: the still grows into place and the
/// player only takes over once the hero has landed.
class PostVideoHero extends StatelessWidget {
  const PostVideoHero({
    super.key,
    required this.tag,
    required this.thumbnailUrl,
    required this.child,
  });

  final String tag;
  final String thumbnailUrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (_, _, _, _, _) =>
          CachedNetworkImage(imageUrl: thumbnailUrl, fit: BoxFit.cover),
      child: child,
    );
  }
}
