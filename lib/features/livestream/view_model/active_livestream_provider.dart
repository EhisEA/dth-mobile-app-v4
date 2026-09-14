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
/// - [LivestreamDetailViewModel] marks it stale when the API reports the
///   stream has ended.
/// - Callers needing a forced refetch (pull-to-refresh on home, lifecycle
///   resume, post-subscribe) can `ref.invalidate(activeLivestreamProvider)`.
final activeLivestreamProvider = FutureProvider<LivestreamCheckResult?>((
  ref,
) async {
  return ref.read(livestreamRepositoryProvider).fetchCheck();
});
