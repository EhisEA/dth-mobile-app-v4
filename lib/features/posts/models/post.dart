import "package:flutter/foundation.dart";

@immutable
class Post {
  const Post({
    required this.uid,
    required this.authorName,
    required this.title,
    this.subtitle,
    this.createdAt,
    required this.description,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    this.viewCount = 0,
    this.viewerReacted = false,
    this.video,
    this.imageUrls = const [],
  });

  final String uid;
  final String authorName;
  final String title;

  /// Optional secondary headline (e.g. "Season 4 Grand Finale"). Mirrors
  /// `TimelinePost.subtitle` from the API.
  final String? subtitle;

  final String? createdAt;
  final String description;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final bool viewerReacted;
  final PostVideo? video;
  final List<String> imageUrls;

  bool get isVideo => video != null;

  Post copyWith({
    String? authorName,
    String? withName,
    String? createdAt,
    String? title,
    String? subtitle,
    String? description,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? viewCount,
    bool? viewerReacted,
    PostVideo? video,
    List<String>? imageUrls,
  }) {
    return Post(
      uid: uid,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      viewerReacted: viewerReacted ?? this.viewerReacted,
      video: video ?? this.video,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}

@immutable
class PostVideo {
  const PostVideo({required this.thumbnailUrl, this.videoUrl, this.provider});

  final String thumbnailUrl;
  final String? videoUrl;
  final String? provider;

  bool get isYoutube {
    if (provider?.trim().toLowerCase() == "youtube") return true;
    final u = videoUrl?.trim();
    if (u == null || u.isEmpty) return false;
    final host = Uri.tryParse(u)?.host.toLowerCase() ?? "";
    return host == "youtu.be" ||
        host.endsWith("youtube.com") ||
        host.endsWith("youtube-nocookie.com");
  }
  bool get isPlayable => videoUrl != null && videoUrl!.trim().isNotEmpty;
}
