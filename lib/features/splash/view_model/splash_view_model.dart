import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/authentication/views/get_started_view.dart";
import "package:dth_v4/features/bottomNavBar/bottom_nav_bar.dart";
import "package:flutter_utils/flutter_utils.dart";

class SplashViewModel extends BaseChangeNotifierViewModel {
  final LocalCache _localCache;
  final AppModulesState _appModulesState;
  SplashViewModel(this._localCache, this._appModulesState);
  final MobileNavigationService _navigationService =
      MobileNavigationService.instance;

  final _log = const AppLogger(SplashViewModel);

  // Cached so the animation can kick off the fetch in parallel and the
  // route handler can just await the same future.
  Future<void>? _modulesPreload;

  /// Fire the modules fetch (idempotent — only one network call regardless
  /// of how many times this is called).
  Future<void> preloadModules() {
    _modulesPreload ??= _fetchModules();
    return _modulesPreload!;
  }

  Future<void> _fetchModules() async {
    try {
      await _appModulesState.fetchModules();
      _log.d("[app modules] ${_appModulesState.appModules.value?.toJson()}");
    } on ApiFailure catch (e) {
      _log.d("[app modules] fetch failed: ${e.message}");
    }
  }

  Future<void> routeFromSplash() async {
    // _localCache.clearCache();
    _log.d(_localCache.getToken());
    _log.d(_localCache.getUserData());

    // Block navigation until modules are resolved so the bottom nav has
    // its tab list ready on first paint. In practice this is almost a
    // no-op because the fetch was kicked off in parallel with the splash
    // animation.
    await preloadModules();

    final bool isLoggedIn = _localCache.getToken() != null;

    if (isLoggedIn) {
      await _navigationService.replace(BottomNavBar.path);
    } else {
      await _navigationService.replace(GetStartedView.path);
    }
  }
}
