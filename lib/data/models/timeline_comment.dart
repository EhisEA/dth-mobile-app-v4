import "package:flutter/foundation.dart";

int _commentAsInt(dynamic v) {
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

String? _commentString(dynamic v) {
  if (v == null) return null;
  if (v is String) {
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
  return v.toString();
}

@immutable
class TimelineCommentUser {
  const TimelineCommentUser({
    required this.fullName,
    this.username,
    this.avatar,
  });

  final String fullName;
  final String? username;
  final String? avatar;

  factory TimelineCommentUser.fromJson(Map<String, dynamic> json) {
    return TimelineCommentUser(
      fullName: _commentString(json["full_name"]) ?? "",
      username: _commentString(json["username"]),
      avatar: _commentString(json["avatar"]),
    );
  }
}

@immutable
class TimelineCommentCounts {
  const TimelineCommentCounts({
    required this.comments,
    required this.reactions,
    required this.shares,
    this.views = 0,
  });

  final int comments;
  final int reactions;
  final int shares;

  /// Backend doesn't include `views` on comment payloads yet — defaults to 0
  /// until the API adds it.
  final int views;

  factory TimelineCommentCounts.fromJson(Map<String, dynamic> json) {
    return TimelineCommentCounts(
      comments: _commentAsInt(json["comments"]),
      reactions: _commentAsInt(json["reactions"]),
      shares: _commentAsInt(json["shares"]),
      views: _commentAsInt(json["views"]),
    );
  }
}

@immutable
class TimelineComment {
  const TimelineComment({
    required this.uid,
    required this.user,
    required this.description,
    required this.type,
    this.parentId,
    required this.counts,
    required this.viewerReacted,
    required this.createdAt,
  });

  final String uid;
  final TimelineCommentUser user;
  final String description;
  final String type;
  final String? parentId;
  final TimelineCommentCounts counts;
  final bool viewerReacted;
  final String createdAt;

  bool get isReply => type.trim().toLowerCase() == "reply";

  factory TimelineComment.fromJson(Map<String, dynamic> json) {
    final userRaw = json["user"];
    final user = userRaw is Map<String, dynamic>
        ? TimelineCommentUser.fromJson(Map<String, dynamic>.from(userRaw))
        : const TimelineCommentUser(fullName: "");

    final countsRaw = json["counts"];
    final counts = countsRaw is Map<String, dynamic>
        ? TimelineCommentCounts.fromJson(Map<String, dynamic>.from(countsRaw))
        : const TimelineCommentCounts(comments: 0, reactions: 0, shares: 0);

    return TimelineComment(
      uid: _commentString(json["uid"]) ?? "",
      user: user,
      description: _commentString(json["description"]) ?? "",
      type: _commentString(json["type"]) ?? "direct",
      parentId: _commentString(json["parent_id"]),
      counts: counts,
      viewerReacted: json["viewer_reacted"] == true,
      createdAt: _commentString(json["created_at"]) ?? "",
    );
  }
}
