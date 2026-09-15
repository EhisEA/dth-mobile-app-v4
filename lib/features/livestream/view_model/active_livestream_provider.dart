import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Cached `GET /livestreams/check` for the home banner.
///
/// Includes [LivestreamCheckResult.accessLivestream] so banner tap can open
/// the subscribe sheet or navigate with [Livestream.videoLink] without a
/// second gated `GET /livestreams`.
///
/// Cache invalidation:
/// - [HomeView.initState] warms it so the banner can render.
/// - Self-invalidates when the signed-in user or their `is_subscribed` flag
///   changes (logout/login, subscription start or expiry via profile refresh),
///   so `access_livestream` never belongs to a previous user or plan.
/// - [LivestreamDetailViewModel] marks it stale when the API reports the
///   stream has ended.
/// - Callers needing a forced refetch (pull-to-refresh on home, lifecycle
///   resume, post-subscribe) can `ref.invalidate(activeLivestreamProvider)`.
final activeLivestreamProvider = FutureProvider<LivestreamCheckResult?>((
  ref,
) async {
  final user = ref.read(userStateProvider).user;
  final fetchedFor = (user.value?.uid, user.value?.isSubscribed);
  void onUserChanged() {
    final current = user.value;
    if ((current?.uid, current?.isSubscribed) != fetchedFor) {
      ref.invalidateSelf();
    }
  }

  user.addListener(onUserChanged);
  ref.onDispose(() => user.removeListener(onUserChanged));

  return ref.read(livestreamRepositoryProvider).fetchCheck();
});
