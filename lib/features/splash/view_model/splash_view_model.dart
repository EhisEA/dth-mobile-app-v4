import "dart:async";

import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/authentication/views/get_started_view.dart";
import "package:dth_v4/features/bottomNavBar/bottom_nav_bar.dart";
import "package:dth_v4/features/home/home.dart";
import "package:flutter_utils/flutter_utils.dart";

class SplashViewModel extends BaseChangeNotifierViewModel {
  final LocalCache _localCache;
  final AppModulesState _appModulesState;
  final SponsorshipsViewModel _sponsorshipsViewModel;
  SplashViewModel(
    this._localCache,
    this._appModulesState,
    this._sponsorshipsViewModel,
  );
  final MobileNavigationService _navigationService =
      MobileNavigationService.instance;

  final _log = const AppLogger(SplashViewModel);

  // Cached so the animation can kick off the fetch in parallel and the
  // route handler can just await the same future.
  Future<void>? _modulesPreload;
  Future<void>? _sponsorshipsPreload;

  /// Fire the modules fetch (idempotent — only one network call regardless
  /// of how many times this is called).
  Future<void> preloadModules() {
    _modulesPreload ??= _fetchModules();
    return _modulesPreload!;
  }

  /// Fire the sponsorships fetch (idempotent).
  Future<void> preloadSponsorships() {
    _sponsorshipsPreload ??= _fetchSponsorships();
    return _sponsorshipsPreload!;
  }

  Future<void> _fetchModules() async {
    try {
      await _appModulesState.fetchModules();
      _log.d("[app modules] ${_appModulesState.appModules.value?.toJson()}");
    } on ApiFailure catch (e) {
      _log.d("[app modules] fetch failed: ${e.message}");
    }
  }

  Future<void> _fetchSponsorships() async {
    try {
      await _sponsorshipsViewModel.load();
      _log.d(
        "[sponsorships] voting sponsors: "
        "${_sponsorshipsViewModel.voting?.sponsors.length ?? 0}",
      );
    } on ApiFailure catch (e) {
      _log.d("[sponsorships] fetch failed: ${e.message}");
    }
  }

  Future<void> routeFromSplash() async {
    // _localCache.clearCache();
    _log.d(_localCache.getToken());
    _log.d(_localCache.getUserData());

    // Block navigation until modules + sponsorships are resolved so the
    // bottom nav and voting sheets have data ready on first paint.
    await Future.wait([preloadModules(), preloadSponsorships()]);

    final bool isLoggedIn = _localCache.getToken() != null;

    // NOT awaited: `replace` -> `pushReplacementNamed` returns a Future that
    // only completes when the destination route is *popped*. Since these are
    // root routes that never get popped, awaiting here would strand
    // `notifyAppReady()` below for the entire session — leaving deep links
    // queued forever. The navigation side-effect happens synchronously, so the
    // route is on the stack by the time we notify.
    if (isLoggedIn) {
      unawaited(_navigationService.replace(BottomNavBar.path));
    } else {
      unawaited(_navigationService.replace(GetStartedView.path));
    }

    // Splash has placed the initial route on the stack — DeepLinkRouter can
    // now safely push the link destination on top (or stash it for the auth
    // flow to consume after login).
    DeepLinkRouter.instance.notifyAppReady();
  }
}
