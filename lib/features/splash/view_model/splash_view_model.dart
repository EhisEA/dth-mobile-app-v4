import "dart:async";

import "package:dth_v4/core/constants/cache_keys.dart";
import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/authentication/views/get_started_view.dart";
import "package:dth_v4/features/bottomNavBar/bottom_nav_bar.dart";
import "package:dth_v4/features/home/home.dart";
import "package:dth_v4/features/voting/view_model/voting_view_model.dart";
import "package:flutter_utils/flutter_utils.dart";

class SplashViewModel extends BaseChangeNotifierViewModel {
  final LocalCache _localCache;
  final AppModulesState _appModulesState;
  final SponsorshipsViewModel _sponsorshipsViewModel;
  final VotingViewModel _votingViewModel;
  SplashViewModel(
    this._localCache,
    this._appModulesState,
    this._sponsorshipsViewModel,
    this._votingViewModel,
  );
  final MobileNavigationService _navigationService =
      MobileNavigationService.instance;

  final _log = const AppLogger(SplashViewModel);

  // Cached so the animation can kick off the fetch in parallel and the
  // route handler can just await the same future.
  Future<void>? _modulesPreload;
  Future<void>? _sponsorshipsPreload;
  Future<void>? _votingWeekPreload;

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

  /// Prefetch voting week (credits + tutorial) when voting is enabled and the
  /// welcome sheet has not been completed yet.
  Future<void> preloadVotingWeekIfNeeded() {
    _votingWeekPreload ??= _fetchVotingWeekIfNeeded();
    return _votingWeekPreload!;
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
    } catch (e) {
      // Optional strip — never let it block splash navigation.
      _log.d("[sponsorships] fetch errored: $e");
    }
  }

  Future<void> _fetchVotingWeekIfNeeded() async {
    await preloadModules();
    final votingEnabled = _appModulesState.appModules.value?.voting == true;
    if (!votingEnabled) return;
    if (_localCache.getFromLocalCache(CacheKeys.votingTutorialSeen) == true) {
      return;
    }
    try {
      await _votingViewModel.preloadWeek();
      _log.d("[voting] week preloaded for tutorial greeting");
    } on ApiFailure catch (e) {
      _log.d("[voting] week preload failed: ${e.message}");
    } catch (e) {
      // Optional prefetch — never let it block splash navigation.
      _log.d("[voting] week preload errored: $e");
    }
  }

  Future<void> routeFromSplash() async {
    // _localCache.clearCache();
    _log.d(_localCache.getToken());
    _log.d(_localCache.getUserData());

    // Block navigation until modules, sponsorships, and (when needed) voting
    // week are resolved so tabs and the voting greeting have data ready.
    // Guarded so an unexpected error in any optional preload can never strand
    // the app on the splash screen — we still route below.

    try {
      await Future.wait([
        preloadModules(), // App cannot start without this
        preloadSponsorships(),
        preloadVotingWeekIfNeeded(),
      ]);
    } catch (e) {
      // Deliberately catch-all: the per-preload handlers only swallow
      // ApiFailure, so a TypeError from a payload shape change, a timeout or a
      // raw socket error would otherwise escape and leave the user on splash
      // with no route at all.
      _log.d("[splash] preload failed, routing anyway: $e");
    }

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
