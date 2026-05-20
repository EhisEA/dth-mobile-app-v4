import "package:flutter/foundation.dart";

@immutable
class Comment {
  const Comment({
    required this.uid,
    required this.authorName,
    this.username,
    this.avatarUrl,
    required this.body,
    required this.timeAgo,
    required this.likeCount,
    required this.replyCount,
    this.shareCount = 0,
    this.viewCount = 0,
    this.viewerReacted = false,
    this.isReply = false,
    this.parentUid,
  });

  final String uid;
  final String authorName;

  /// Optional `@handle` shown alongside the name. Backend doesn't expose this
  /// yet — populated only when the API adds a `user.username` field.
  final String? username;

  final String? avatarUrl;
  final String body;
  final String timeAgo;
  final int likeCount;
  final int replyCount;
  final int shareCount;

  /// Backend doesn't expose comment view counts yet — stays 0 until the API
  /// adds `counts.views` to the comment payload.
  final int viewCount;

  final bool viewerReacted;
  final bool isReply;
  final String? parentUid;

  Comment copyWith({
    String? body,
    int? likeCount,
    int? replyCount,
    int? shareCount,
    int? viewCount,
    bool? viewerReacted,
  }) {
    return Comment(
      uid: uid,
      authorName: authorName,
      username: username,
      avatarUrl: avatarUrl,
      body: body ?? this.body,
      timeAgo: timeAgo,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      viewerReacted: viewerReacted ?? this.viewerReacted,
      isReply: isReply,
      parentUid: parentUid,
    );
  }
}
