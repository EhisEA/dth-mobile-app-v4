import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class NotificationsViewModel extends BaseChangeNotifierViewModel {
  NotificationsViewModel(this._repo);

  final NotificationsRepo _repo;

  static const String _markAllReadKey = "notificationsMarkAllRead";

  List<NotificationItem> _items = const [];
  List<NotificationItem> get items => _items;

  /// Uids optimistically marked read while PATCH is in flight — keeps stale
  /// refresh responses from flipping a tile back to unread.
  final Set<String> _pendingReadUids = {};

  String? _nextCursor;
  bool get hasMore => _nextCursor != null;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  bool get hasUnread => _items.any((n) => !n.isRead);

  List<NotificationItem> _withLocalReadState(List<NotificationItem> items) {
    if (_pendingReadUids.isEmpty) return items;
    return [
      for (final n in items)
        _pendingReadUids.contains(n.uid) || n.isRead
            ? n.copyWith(isRead: true)
            : n,
    ];
  }

  /// [nextCursor] is required and assigned as-is: a null cursor is the server
  /// saying "last page", so it must clear [_nextCursor] rather than leave a
  /// stale one behind (which would keep [hasMore] true and re-fetch forever).
  void _setItems(List<NotificationItem> items, {required String? nextCursor}) {
    _items = _withLocalReadState(
      items.where((n) => n.hasDisplayContent).toList(growable: false),
    );
    _nextCursor = nextCursor;
  }

  /// Silent first-page fetch for the home header badge (no busy skeleton).
  Future<void> prefetchUnreadBadge() async {
    try {
      final page = await _repo.fetchNotifications();
      _setItems(page.items, nextCursor: page.nextCursor);
      notifyListeners();
    } catch (_) {
      // Badge prefetch is best-effort; home must not surface errors.
    }
  }

  ViewModelState get markAllReadState =>
      getState(_markAllReadKey) ?? const ViewModelState.idle();

  bool get markAllReadBusy =>
      markAllReadState.maybeWhen(busy: () => true, orElse: () => false);

  Future<void> loadFirstPage() async {
    try {
      changeBaseState(const ViewModelState.busy());
      final page = await _repo.fetchNotifications();
      _setItems(page.items, nextCursor: page.nextCursor);
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
    }
  }

  Future<void> refresh() async {
    try {
      final page = await _repo.fetchNotifications();
      _setItems(page.items, nextCursor: page.nextCursor);
    } on ApiFailure catch (e) {
      showErrorFlushbar(title: "Notifications", message: e.message);
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _repo.fetchNotifications(cursor: cursor);
      _setItems([..._items, ...page.items], nextCursor: page.nextCursor);
    } on ApiFailure catch (e) {
      showErrorFlushbar(title: "Notifications", message: e.message);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String uid) async {
    final index = _items.indexWhere((n) => n.uid == uid);
    if (index < 0) return;
    final current = _items[index];
    if (current.isRead) return;

    _pendingReadUids.add(uid);
    final previous = _items;
    _items = [
      for (var i = 0; i < _items.length; i++)
        if (i == index) current.copyWith(isRead: true) else _items[i],
    ];
    notifyListeners();

    try {
      await _repo.markNotificationRead(uid);
      _pendingReadUids.remove(uid);
    } on ApiFailure catch (e) {
      _pendingReadUids.remove(uid);
      _items = previous;
      notifyListeners();
      showErrorFlushbar(title: "Notifications", message: e.message);
    }
  }

  Future<bool> markAllAsRead() async {
    if (markAllReadBusy || !hasUnread) return false;

    setState(_markAllReadKey, const ViewModelState.busy());
    try {
      await _repo.markAllNotificationsRead();
      _pendingReadUids.clear();
      _items = [for (final n in _items) n.copyWith(isRead: true)];
      setState(_markAllReadKey, const ViewModelState.idle());
      notifyListeners();
      return true;
    } on ApiFailure catch (e) {
      setState(_markAllReadKey, const ViewModelState.idle());
      showErrorFlushbar(title: "Notifications", message: e.message);
      return false;
    }
  }
}

final notificationsViewModelProvider =
    ChangeNotifierProvider<NotificationsViewModel>((ref) {
      return NotificationsViewModel(ref.read(notificationsRepositoryProvider));
    });
