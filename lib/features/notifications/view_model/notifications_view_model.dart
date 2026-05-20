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

  String? _nextCursor;
  bool get hasMore => _nextCursor != null;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  bool get hasUnread => _items.any((n) => !n.isRead);

  ViewModelState get markAllReadState =>
      getState(_markAllReadKey) ?? const ViewModelState.idle();

  bool get markAllReadBusy =>
      markAllReadState.maybeWhen(busy: () => true, orElse: () => false);

  Future<void> loadFirstPage() async {
    try {
      changeBaseState(const ViewModelState.busy());
      final page = await _repo.fetchNotifications();
      _items = page.items;
      _nextCursor = page.nextCursor;
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
    }
  }

  Future<void> refresh() async {
    try {
      final page = await _repo.fetchNotifications();
      _items = page.items;
      _nextCursor = page.nextCursor;
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
      _items = [..._items, ...page.items];
      _nextCursor = page.nextCursor;
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

    final previous = _items;
    _items = [
      for (var i = 0; i < _items.length; i++)
        if (i == index) current.copyWith(isRead: true) else _items[i],
    ];
    notifyListeners();

    try {
      await _repo.markNotificationRead(uid);
    } on ApiFailure catch (e) {
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
