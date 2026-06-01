import "dart:async";

import "package:dth_v4/core/constants/deep_linking_keys.dart";
import "package:dth_v4/core/provider.dart";
import "package:dth_v4/core/router/routing_argument_keys.dart";
import "package:dth_v4/core/router/routing_constants.dart";
import "package:dth_v4/core/services/deep_link_service.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Pending deep link captured while the user is logged out. The auth flow
/// reads-and-clears this after a successful sign-in so the user lands on the
/// link's destination instead of the default home.
final pendingDeepLinkProvider = StateProvider<DeepLink?>((ref) => null);

/// Subscribes to [DeepLinkService.instance.links] and routes each tap through
/// [MobileNavigationService]. Links that arrive before [notifyAppReady] (e.g.
/// during the splash delay) are queued and drained when the navigator is live.
///
/// Auth-required links received while logged out are stashed in
/// [pendingDeepLinkProvider] for the post-login handoff.
class DeepLinkRouter {
  DeepLinkRouter._(this._container);

  static DeepLinkRouter? _instance;
  static DeepLinkRouter get instance {
    final i = _instance;
    assert(i != null, "DeepLinkRouter.bootstrap was never called");
    return i!;
  }

  static void bootstrap(ProviderContainer container) {
    if (_instance != null) return;
    _instance = DeepLinkRouter._(container).._start();
  }

  static const _logger = AppLogger(DeepLinkRouter);

  final ProviderContainer _container;
  final MobileNavigationService _nav = MobileNavigationService.instance;
  StreamSubscription<DeepLink>? _sub;

  /// False until the splash flow has finished routing to its initial
  /// destination. Without this gate, a link dispatched during cold start would
  /// race the splash's `pushReplacement` and get blown away.
  bool _ready = false;
  DeepLink? _queued;

  void _start() {
    _sub = DeepLinkService.instance.links.listen(
      _handle,
      onError: (Object err) => _logger.e("DeepLink stream error: $err"),
    );
  }

  /// Called by the splash flow once it has settled on a destination route.
  /// Flushes any link buffered during cold start.
  void notifyAppReady() {
    if (_ready) return;
    _ready = true;
    final pending = _queued;
    if (pending != null) {
      _queued = null;
      _handle(pending);
    }
  }

  void _handle(DeepLink link) {
    if (!_ready) {
      _queued = link;
      return;
    }

    final isAuthed = _container.read(localCacheProvider).getToken() != null;
    final requiresAuth = _requiresAuth(link.path);

    if (requiresAuth && !isAuthed) {
      _container.read(pendingDeepLinkProvider.notifier).state = link;
      return;
    }

    dispatch(link);
  }

  /// Replays a link that was stashed in [pendingDeepLinkProvider] while the
  /// user was logged out. Called when the authenticated shell (home) opens —
  /// reaching home guarantees the user is authed, so the link's auth gate is
  /// already satisfied. Reads-and-clears so the link dispatches at most once;
  /// a no-op when nothing is pending.
  void consumePendingLink() {
    final pending = _container.read(pendingDeepLinkProvider);
    if (pending == null) return;
    _container.read(pendingDeepLinkProvider.notifier).state = null;
    dispatch(pending);
  }

  /// Routes a link to its destination view. Public so the auth flow can call
  /// it after consuming [pendingDeepLinkProvider] post-login.
  Future<void> dispatch(DeepLink link) async {
    try {
      await _dispatch(link);
    } catch (err, st) {
      _logger.e("Deep link dispatch/push failed: $err\n$st");
    }
  }

  Future<void> _dispatch(DeepLink link) async {
    switch (link.path) {
      case DeepLinkPaths.timeline:
        final uid = link.data[DeepLinkParams.postId] as String?;
        if (uid == null || uid.isEmpty) return _warnMissing(link, "postId");
        await _nav.push(
          NavigatorRoutes.postDetail,
          extra: {RoutingArgumentKey.postUid: uid},
        );

      case DeepLinkPaths.comment:
        final uid = link.data[DeepLinkParams.commentId] as String?;
        if (uid == null || uid.isEmpty) return _warnMissing(link, "commentId");
        await _nav.push(
          NavigatorRoutes.commentThread,
          extra: {RoutingArgumentKey.commentUid: uid},
        );

      case DeepLinkPaths.event:
        final uid = link.data[DeepLinkParams.eventId] as String?;
        if (uid == null || uid.isEmpty) return _warnMissing(link, "eventId");
        await _nav.push(
          NavigatorRoutes.show,
          extra: {RoutingArgumentKey.eventUid: uid},
        );

      case DeepLinkPaths.reel:
        final uid = link.data[DeepLinkParams.reelUid] as String?;
        if (uid == null || uid.isEmpty) return _warnMissing(link, "reelUid");
        await _nav.push(
          NavigatorRoutes.stories,
          extra: {RoutingArgumentKey.reelUid: uid},
        );

      case DeepLinkPaths.referral:
        // No dedicated destination view yet. The referral code is stashed via
        // [pendingDeepLinkProvider] for the onboarding/application flow to
        // pick up when it's wired.
        final code = link.data[DeepLinkParams.referralCode];
        _logger.w("Referral link has no destination view yet (code=$code)");

      default:
        _logger.w("Unknown deep link path: ${link.path}");
    }
  }

  /// All current link types except referral land on authenticated views. If
  /// the user receives one logged out, we stash and let the auth flow consume
  /// it after login.
  bool _requiresAuth(String? path) {
    if (path == DeepLinkPaths.referral) return false;
    return true;
  }

  void _warnMissing(DeepLink link, String field) {
    _logger.w("Deep link ${link.path} missing $field — data=${link.data}");
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _instance = null;
  }
}
