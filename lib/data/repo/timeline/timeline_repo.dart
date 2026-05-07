import "package:dth_v4/data/models/model.dart";

abstract class TimelineRepo {
  /// Fetches one page of timeline posts. Pass [cursor] (from a prior result's
  /// `nextCursor`) to load the next page.
  Future<PaginatedResult<TimelinePost>> fetchTimeline({String? cursor});

  /// Fetches one page of timeline reels. Pass [cursor] for the next page.
  Future<PaginatedResult<TimelineReel>> fetchTimelineReels({String? cursor});
}
