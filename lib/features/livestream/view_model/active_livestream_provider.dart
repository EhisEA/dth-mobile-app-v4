import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/// One-shot cached lookup of the currently active livestream. The icon tap
/// reads this synchronously (`ref.read(...)`) and dispatches off the cached
/// AsyncValue — no fresh HTTP call is issued on the tap itself.
///
/// Cache invalidation:
/// - [HomeView.initState] warms it so the value is ready by the time the
///   user can tap.
/// - [LivestreamDetailViewModel] marks it stale when the API reports the
///   stream has ended, so the next tap from home falls through to the
///   "no active livestream" flushbar instead of routing into an empty
///   view.
/// - Callers needing a forced refetch (pull-to-refresh on home, lifecycle
///   resume) can `ref.invalidate(activeLivestreamProvider)`.
final activeLivestreamProvider = FutureProvider<Livestream?>((ref) async {
  return ref.read(livestreamRepositoryProvider).fetchActive();
});
