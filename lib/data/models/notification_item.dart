import "package:dth_v4/data/models/notification_user.dart";

class NotificationItem {
  const NotificationItem({
    required this.uid,
    required this.title,
    required this.description,
    this.user,
    this.readAt,
    required this.isRead,
    required this.createdAt,
  });

  final String uid;
  final String title;
  final String description;
  final NotificationUser? user;
  final String? readAt;
  final bool isRead;
  final String createdAt;

  bool get isSystemStyle {
    final u = user;
    if (u == null) return true;
    final name = u.name?.trim() ?? "";
    final avatar = u.avatar?.trim() ?? "";
    return name.isEmpty && avatar.isEmpty;
  }

  /// Bold prefix when [title] starts with the actor's name.
  String? get titleBoldPrefix {
    final name = user?.name?.trim();
    if (name == null || name.isEmpty) return null;
    if (!title.startsWith(name)) return null;
    return name;
  }

  String get titleRemainder {
    final prefix = titleBoldPrefix;
    if (prefix == null) return title;
    return title.substring(prefix.length).trimLeft();
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final uidRaw = json["uid"];
    final titleRaw = json["title"];
    final descRaw = json["description"];
    final readAtRaw = json["read_at"];
    final isReadRaw = json["is_read"];
    final createdAtRaw = json["created_at"];

    NotificationUser? user;
    final userRaw = json["user"];
    if (userRaw is Map<String, dynamic>) {
      user = NotificationUser.fromJson(userRaw);
    } else if (userRaw is Map) {
      user = NotificationUser.fromJson(Map<String, dynamic>.from(userRaw));
    }

    return NotificationItem(
      uid: uidRaw is String ? uidRaw : "",
      title: titleRaw is String ? titleRaw.trim() : "",
      description: descRaw is String ? descRaw.trim() : "",
      user: user,
      readAt: readAtRaw is String ? readAtRaw : null,
      isRead: isReadRaw == true,
      createdAt: createdAtRaw is String ? createdAtRaw.trim() : "",
    );
  }

  NotificationItem copyWith({bool? isRead, String? readAt}) {
    return NotificationItem(
      uid: uid,
      title: title,
      description: description,
      user: user,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
