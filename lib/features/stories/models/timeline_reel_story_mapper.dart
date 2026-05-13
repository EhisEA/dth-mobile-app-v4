import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/stories/models/story.dart";

/// Maps API [TimelineReel] to UI [Story] — just the thumbnail + label the
/// stories bar needs. Anything richer (description, video, like state) is
/// pulled from `ReelsCache` by [StoriesView] when the tile is tapped.
Story storyFromTimelineReel(TimelineReel r) {
  final thumb = r.media?.thumbnail?.trim();
  final videoThumb = r.videoThumbnail?.trim();
  final mediaUrl = r.media?.url?.trim() ?? "";

  final imageUrl = (thumb != null && thumb.isNotEmpty)
      ? thumb
      : (videoThumb != null && videoThumb.isNotEmpty)
      ? videoThumb
      : (mediaUrl.isNotEmpty ? mediaUrl : "");
  final label = r.title.trim().isNotEmpty ? r.title.trim() : "Reel";

  return Story(uid: r.uid, imageUrl: imageUrl, label: label);
}
