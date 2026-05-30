import "package:flutter/foundation.dart";

int _livestreamAsInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final s = v.trim().replaceAll(",", "");
    if (s.isEmpty) return 0;
    return int.tryParse(s) ?? double.tryParse(s)?.round() ?? 0;
  }
  return 0;
}

String? _livestreamString(dynamic v) {
  if (v == null) return null;
  if (v is String) {
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
  return v.toString();
}

@immutable
class LivestreamCounts {
  const LivestreamCounts({
    required this.comments,
    required this.reactions,
    required this.views,
    required this.shares,
  });

  final int comments;
  final int reactions;
  final int views;
  final int shares;

  factory LivestreamCounts.fromJson(Map<String, dynamic> json) {
    return LivestreamCounts(
      comments: _livestreamAsInt(json["comments"]),
      reactions: _livestreamAsInt(json["reactions"]),
      views: _livestreamAsInt(json["views"]),
      shares: _livestreamAsInt(json["shares"]),
    );
  }
}

/// API model for the active livestream (`GET /api/livestreams`).
/// Always a video — no subtitle, no image media, no replies on its comments.
@immutable
class Livestream {
  const Livestream({
    required this.uid,
    required this.title,
    required this.description,
    this.videoLink,
    this.videoThumbnail,
    required this.status,
    required this.counts,
    required this.viewerReacted,
    required this.createdAt,
  });

  final String uid;
  final String title;
  final String description;
  final String? videoLink;
  final String? videoThumbnail;

  /// API string — `"active"` when the stream is live. The endpoint only ever
  /// returns the active stream, but the field is kept around so the UI can
  /// label it if needed.
  final String status;

  final LivestreamCounts counts;
  final bool viewerReacted;
  final String createdAt;

  bool get isActive => status.trim().toLowerCase() == "active";

  factory Livestream.fromJson(Map<String, dynamic> json) {
    final countsRaw = json["counts"];
    final counts = countsRaw is Map<String, dynamic>
        ? LivestreamCounts.fromJson(Map<String, dynamic>.from(countsRaw))
        : const LivestreamCounts(
            comments: 0,
            reactions: 0,
            views: 0,
            shares: 0,
          );

    return Livestream(
      uid: _livestreamString(json["uid"]) ?? "",
      title: _livestreamString(json["title"]) ?? "",
      description: _livestreamString(json["description"]) ?? "",
      videoLink: _livestreamString(json["video_link"]),
      videoThumbnail: _livestreamString(json["video_thumbnail"]),
      status: _livestreamString(json["status"]) ?? "",
      counts: counts,
      viewerReacted: json["viewer_reacted"] == true,
      createdAt: _livestreamString(json["created_at"]) ?? "",
    );
  }
}
