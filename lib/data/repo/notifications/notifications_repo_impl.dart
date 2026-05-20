import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class NotificationsRepoImpl implements NotificationsRepo {
  NotificationsRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<PaginatedResult<NotificationItem>> fetchNotifications({
    String? cursor,
  }) async {
    final response = await _networkService.get(
      ApiRoute.notifications,
      queryParams: _cursorParams(cursor),
    );
    return _parsePaginated(
      response.data,
      listKey: "notifications",
      fromJson: NotificationItem.fromJson,
    );
  }

  @override
  Future<void> markNotificationRead(String uid) async {
    await _networkService.patch(ApiRoute.notificationRead(uid));
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _networkService.post(
      ApiRoute.notificationsReadAll,
      data: <String, dynamic>{},
    );
  }

  Map<String, dynamic>? _cursorParams(String? cursor) {
    if (cursor == null || cursor.isEmpty) return null;
    return {"cursor": cursor};
  }

  PaginatedResult<T> _parsePaginated<T>(
    dynamic root, {
    required String listKey,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final empty = PaginatedResult<T>(items: const [], nextCursor: null);
    if (root is! Map<String, dynamic>) return empty;
    final data = root["data"];
    if (data is! Map<String, dynamic>) return empty;
    final outer = data[listKey];
    if (outer is! Map<String, dynamic>) return empty;
    final list = outer["data"];
    if (list is! List<dynamic>) return empty;

    final cursorRaw = outer["next_cursor"];
    final nextCursor = cursorRaw is String && cursorRaw.isNotEmpty
        ? cursorRaw
        : null;

    final items = list
        .map((e) {
          if (e is! Map) return null;
          return fromJson(Map<String, dynamic>.from(e));
        })
        .whereType<T>()
        .toList();

    return PaginatedResult<T>(items: items, nextCursor: nextCursor);
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepo>((ref) {
  return NotificationsRepoImpl(
    networkService: ref.read(networkServiceProvider),
  );
});
