import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// Cached `GET /livestreams/check` for the home banner. Not subscription-gated
/// — use [LivestreamRepo.fetchActive] on banner tap to enforce access.
///
/// Cache invalidation:
/// - [HomeView.initState] warms it so the banner can render.
/// - [LivestreamDetailViewModel] marks it stale when the API reports the
///   stream has ended.
/// - Callers needing a forced refetch (pull-to-refresh on home, lifecycle
///   resume, post-subscribe) can `ref.invalidate(activeLivestreamProvider)`.
final activeLivestreamProvider = FutureProvider<Livestream?>((ref) async {
  return ref.read(livestreamRepositoryProvider).fetchCheck();
});
