import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:intl/intl.dart";
import "package:youtube_player_flutter/youtube_player_flutter.dart";

/// Splits a feed title formatted as "X with Y" into (author, withName).
/// Falls back gracefully when the separator is missing or the title is empty.
(String, String?) parsePostTitle(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) {
    return ("", null);
  }
  final lower = trimmed.toLowerCase();
  const sep = " with ";
  final idx = lower.indexOf(sep);
  if (idx == -1) {
    return ("", trimmed);
  }
  final author = trimmed.substring(0, idx).trim();
  final withPart = trimmed.substring(idx + sep.length).trim();
  return (
    author.isEmpty ? trimmed : author,
    withPart.isEmpty ? null : withPart,
  );
}

String formatTimeAgo(String createdAt) {
  final trimmed = createdAt.trim();
  if (trimmed.isEmpty) {
    return "";
  }
  try {
    final dt = DateTime.parse(trimmed).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.isNegative) {
      return DateFormat.yMMMd().format(dt);
    }
    if (diff.inMinutes < 1) {
      return "Just now";
    }
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    }
    if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    }
    if (diff.inDays < 7) {
      return "${diff.inDays}d ago";
    }
    return DateFormat.yMMMd().format(dt);
  } on FormatException {
    // Some list endpoints (e.g. `/timeline-reels`) return `created_at` as a
    // pre-formatted phrase like `"2 hours ago"` instead of an ISO timestamp.
    // Pass that through so we don't drop perfectly good data on the floor.
    return trimmed;
  }
}

/// YouTube video id from a standard thumbnail URL (`img.youtube.com`, `i.ytimg.com`).
String? _youtubeIdFromThumbnailUrl(String url) {
  if (url.isEmpty) return null;
  final m = RegExp(r"/vi/([^/?#]+)/").firstMatch(url);
  return m?.group(1);
}

/// Same edge cases as [YoutubePlayer.convertUrlToId] misses on some hosts/paths.
String? _youtubeIdFromVideoUrlFallback(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  if (host == "youtu.be") {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  final isYouTube =
      host.endsWith("youtube.com") || host.endsWith("youtube-nocookie.com");
  if (!isYouTube) return null;
  final segs = uri.pathSegments;
  if (segs.length >= 2 && (segs[0] == "embed" || segs[0] == "shorts")) {
    return segs[1];
  }
  final v = uri.queryParameters["v"];
  if (v != null && v.isNotEmpty) return v;
  return null;
}

String? _resolvedYoutubeVideoId(String link, String thumb) {
  if (link.isNotEmpty) {
    return YoutubePlayer.convertUrlToId(link) ??
        _youtubeIdFromVideoUrlFallback(link);
  }
  if (thumb.isNotEmpty) {
    return _youtubeIdFromThumbnailUrl(thumb);
  }
  return null;
}

Post postFromTimelinePost(TimelinePost p) {
  final parsed = parsePostTitle(p.title);
  final authorName = parsed.$1;
  final withName = parsed.$2;
  final typeLower = p.type.trim().toLowerCase();
  final link = p.videoLink?.trim() ?? "";
  final thumb = p.videoThumbnail?.trim() ?? "";
  final youtubeId = _resolvedYoutubeVideoId(link, thumb);

  // Previously required a non-empty thumbnail, so posts with only `video_link`
  // never became `Post.isVideo` and the detail player never mounted.
  final isVideo = typeLower == "video" &&
      (link.isNotEmpty || thumb.isNotEmpty || youtubeId != null);

  final resolvedLink = link.isNotEmpty
      ? link
      : (youtubeId != null ? "https://www.youtube.com/watch?v=$youtubeId" : "");

  final resolvedThumb = thumb.isNotEmpty
      ? thumb
      : (youtubeId != null
          ? "https://img.youtube.com/vi/$youtubeId/hqdefault.jpg"
          : "");

  final imageUrls = <String>[];
  if (!isVideo && p.media != null) {
    imageUrls.addAll(p.media!);
  }

  return Post(
    uid: p.uid,
    title: p.title.trim(),
    subtitle: p.subtitle?.trim().isNotEmpty == true ? p.subtitle!.trim() : null,
    authorName: p.authorName ?? withName ?? authorName,
    createdAt: p.createdAt,
    description: p.description.trim(),
    likeCount: p.counts.reactions,
    commentCount: p.counts.comments,
    shareCount: p.counts.shares,
    viewCount: p.counts.views,
    viewerReacted: p.viewerReacted,
    video: isVideo
        ? PostVideo(
            thumbnailUrl: resolvedThumb,
            videoUrl: resolvedLink.isNotEmpty ? resolvedLink : null,
            provider: p.videoType?.trim(),
          )
        : null,
    imageUrls: imageUrls,
  );
}
