import "package:flutter/foundation.dart";

int _timelineAsInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final normalized = v.trim().replaceAll(",", "");
    if (normalized.isEmpty) return 0;
    final asDouble = double.tryParse(normalized);
    if (asDouble != null) return asDouble.round();
    return int.tryParse(normalized) ?? 0;
  }
  final parsed = double.tryParse(v.toString().replaceAll(",", ""));
  if (parsed != null) return parsed.round();
  return 0;
}

String? _timelineString(dynamic v) {
  if (v == null) return null;
  if (v is String) {
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
  return v.toString();
}

@immutable
class TimelinePostCounts {
  const TimelinePostCounts({
    required this.comments,
    required this.reactions,
    required this.views,
    required this.shares,
  });

  final int comments;
  final int reactions;
  final int views;
  final int shares;

  factory TimelinePostCounts.fromJson(Map<String, dynamic> json) {
    return TimelinePostCounts(
      comments: _timelineAsInt(json["comments"]),
      reactions: _timelineAsInt(json["reactions"]),
      views: _timelineAsInt(json["views"]),
      shares: _timelineAsInt(json["shares"]),
    );
  }
}

@immutable
class TimelinePost {
  const TimelinePost({
    required this.uid,
    required this.title,
    this.subtitle,
    required this.description,
    required this.type,
    required this.authorName,
    this.videoType,
    this.videoLink,
    this.videoThumbnail,
    this.media,
    required this.counts,
    required this.viewerReacted,
    required this.createdAt,
  });

  final String uid;
  final String title;

  /// Optional secondary headline (e.g. "Season 4 Grand Finale"). Always
  /// present in the API contract but frequently `null` in practice.
  final String? subtitle;

  final String? authorName;
  final String description;
  final String type;
  final String? videoType;
  final String? videoLink;
  final String? videoThumbnail;
  final List<String>? media;
  final TimelinePostCounts counts;
  final bool viewerReacted;
  final String createdAt;

  factory TimelinePost.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json["media"];
    List<String>? media;
    if (mediaRaw is List<dynamic>) {
      final urls = <String>[];
      for (final e in mediaRaw) {
        if (e is String && e.trim().isNotEmpty) {
          urls.add(e.trim());
        } else if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          final u = _timelineString(m["url"] ?? m["src"] ?? m["path"]);
          if (u != null) urls.add(u);
        }
      }
      media = urls.isEmpty ? null : urls;
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

    return TimelinePost(
      uid: _timelineString(json["uid"]) ?? "",
      title: _timelineString(json["title"]) ?? "",
      subtitle: _timelineString(json["subtitle"]),
      description: _timelineString(json["description"]) ?? "",
      type: _timelineString(json["type"]) ?? "",
      videoType: _timelineString(json["video_type"]),
      videoLink: _timelineString(json["video_link"]),
      authorName: _timelineString(json["author_name"]),
      videoThumbnail: _timelineString(json["video_thumbnail"]),
      media: media,
      counts: counts,
      viewerReacted: json["viewer_reacted"] == true,
      createdAt: _timelineString(json["created_at"]) ?? "",
    );
  }
}
