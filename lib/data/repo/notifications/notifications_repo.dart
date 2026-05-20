import "package:dth_v4/data/models/notification_item.dart";
import "package:dth_v4/data/models/paginated_result.dart";

abstract class NotificationsRepo {
  Future<PaginatedResult<NotificationItem>> fetchNotifications({
    String? cursor,
  });

  Future<void> markNotificationRead(String uid);

  Future<void> markAllNotificationsRead();
}
