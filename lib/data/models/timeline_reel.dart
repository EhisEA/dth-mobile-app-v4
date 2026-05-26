import "package:dth_v4/data/models/timeline_post.dart";
import "package:flutter/foundation.dart";

String? _reelString(dynamic v) {
  if (v == null) return null;
  if (v is String) {
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
  return v.toString();
}

@immutable
class TimelineReelMedia {
  const TimelineReelMedia({this.url, this.thumbnail, this.mimeType});

  final String? url;
  final String? thumbnail;
  final String? mimeType;

  factory TimelineReelMedia.fromJson(Map<String, dynamic> json) {
    return TimelineReelMedia(
      url: _reelString(json["url"]),
      thumbnail: _reelString(json["thumbnail"]),
      mimeType: _reelString(json["mime_type"]),
    );
  }
}

@immutable
class TimelineReel {
  const TimelineReel({
    required this.uid,
    required this.title,
    required this.description,
    this.videoType,
    this.videoLink,
    this.videoThumbnail,
    this.media,
    required this.counts,
    required this.createdAt,
    this.viewerReacted = false,
  });

  final String uid;
  final String title;
  final String description;
  final String? videoType;
  final String? videoLink;
  final String? videoThumbnail;
  final TimelineReelMedia? media;
  final TimelinePostCounts counts;
  final String createdAt;
  final bool viewerReacted;

  factory TimelineReel.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json["media"];
    TimelineReelMedia? media;
    if (mediaRaw is Map) {
      media = TimelineReelMedia.fromJson(Map<String, dynamic>.from(mediaRaw));
    }

    final countsRaw = json["counts"];
    final counts = countsRaw is Map<String, dynamic>
        ? TimelinePostCounts.fromJson(Map<String, dynamic>.from(countsRaw))
        : const TimelinePostCounts(
            comments: 0,
            reactions: 0,
            views: 0,
            shares: 0,
          );

    return TimelineReel(
      uid: _reelString(json["uid"]) ?? "",
      title: _reelString(json["title"]) ?? "",
      description: _reelString(json["description"]) ?? "",
      videoType: _reelString(json["video_type"]),
      videoLink: _reelString(json["video_link"]),
      videoThumbnail: _reelString(json["video_thumbnail"]),
      media: media,
      counts: counts,
      createdAt: _reelString(json["created_at"]) ?? "",
      viewerReacted: json["viewer_reacted"] == true,
    );
  }
}
