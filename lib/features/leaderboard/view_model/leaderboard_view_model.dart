import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class LeaderboardViewModel extends BaseChangeNotifierViewModel {
  LeaderboardViewModel(this._repo);

  final FanLeaderboardRepo _repo;

  String _title = "Leaderboard";
  String get title => _title;

  String _subtitle = "Leaderboard";
  String get subtitle => _subtitle;

  List<FanLeaderboardEntry> _podium = const [];
  List<FanLeaderboardEntry> get podium => _podium;

  FanLeaderboardEntry? _currentUser;
  FanLeaderboardEntry? get currentUser => _currentUser;

  List<FanLeaderboardEntry> _participants = const [];
  List<FanLeaderboardEntry> get participants => _participants;

  FanLeaderboardGuide? _guide;
  FanLeaderboardGuide? get guide => _guide;

  String? _nextCursor;
  bool _hasMore = false;
  bool get hasMore => _hasMore && _nextCursor != null;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  Future<void> load() async {
    try {
      changeBaseState(const ViewModelState.busy());
      final page = await _repo.fetch();
      _applyFirstPage(page);
      changeBaseState(const ViewModelState.idle());
    } on ApiFailure catch (e) {
      changeBaseState(ViewModelState.error(e));
    }
  }

  Future<void> refresh() async {
    try {
      final page = await _repo.fetch();
      _applyFirstPage(page);
    } on ApiFailure catch (e) {
      showErrorFlushbar(title: "Leaderboard", message: e.message);
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (!_hasMore || cursor == null || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _repo.fetch(cursor: cursor);
      _participants = [..._participants, ...page.participants];
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
    } on ApiFailure catch (e) {
      showErrorFlushbar(title: "Leaderboard", message: e.message);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void _applyFirstPage(FanLeaderboardData page) {
    _title = page.title;
    _subtitle = page.subtitle;
    _podium = page.podium;
    _currentUser = page.currentUser;
    _participants = page.participants;
    _guide = page.guide;
    _nextCursor = page.nextCursor;
    _hasMore = page.hasMore;
  }
}

final leaderboardViewModelProvider =
    ChangeNotifierProvider<LeaderboardViewModel>((ref) {
      return LeaderboardViewModel(ref.read(fanLeaderboardRepositoryProvider));
    });
