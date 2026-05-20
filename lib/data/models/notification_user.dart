class NotificationUser {
  const NotificationUser({this.name, this.avatar});

  final String? name;
  final String? avatar;

  factory NotificationUser.fromJson(Map<String, dynamic> json) {
    final nameRaw = json["name"];
    final avatarRaw = json["avatar"];
    return NotificationUser(
      name: nameRaw is String ? nameRaw.trim() : null,
      avatar: avatarRaw is String ? avatarRaw.trim() : null,
    );
  }
}
