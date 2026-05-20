import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class ReelCommentRepoImpl implements ReelCommentRepo {
  ReelCommentRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<TimelineReel> fetchReel(String reelUid) async {
    final response = await _networkService.get(
      ApiRoute.timelineReelDetail(reelUid),
    );
    return _parseReel(response.data, ["reel"]);
  }

  @override
  Future<PaginatedResult<TimelineComment>> listComments(
    String reelUid, {
    String? cursor,
    CommentSort sort = CommentSort.latest,
  }) async {
    final response = await _networkService.get(
      ApiRoute.timelineReelComments(reelUid),
      queryParams: _listParams(cursor: cursor, sort: sort),
    );
    return _parsePaginated(response.data, listKey: "comments");
  }

  @override
  Future<TimelineComment> createComment(String reelUid, String body) async {
    final response = await _networkService.post(
      ApiRoute.timelineReelComments(reelUid),
      data: {"description": body},
    );
    return _parseComment(response.data, ["comment"]);
  }

  @override
  Future<TimelineComment> toggleCommentReaction(String commentUid) async {
    final response = await _networkService.post(
      ApiRoute.timelineReelCommentReact(commentUid),
    );
    return _parseComment(response.data, ["comment"]);
  }

  @override
  Future<TimelineReel> toggleReelReaction(String reelUid) async {
    final response = await _networkService.post(
      ApiRoute.timelineReelReact(reelUid),
    );
    return _parseReel(response.data, ["reel"]);
  }

  Map<String, dynamic>? _listParams({String? cursor, CommentSort? sort}) {
    final params = <String, dynamic>{};
    if (cursor != null && cursor.isNotEmpty) params["cursor"] = cursor;
    if (sort != null) params["sort"] = sort.apiValue;
    return params.isEmpty ? null : params;
  }

  /// Mirrors the cursor envelope parser in [CommentRepoImpl] — same shape:
  /// `{ data: { <listKey>: { data: [...], next_cursor: "..." } } }`.
  PaginatedResult<TimelineComment> _parsePaginated(
    dynamic root, {
    required String listKey,
  }) {
    const empty = PaginatedResult<TimelineComment>(
      items: [],
      nextCursor: null,
    );
    if (root is! Map<String, dynamic>) return empty;
    final data = root["data"];
    if (data is! Map<String, dynamic>) return empty;
    final outer = data[listKey];
    if (outer is! Map<String, dynamic>) return empty;
    final list = outer["data"];
    if (list is! List<dynamic>) return empty;

    final cursorRaw = outer["next_cursor"];
    final nextCursor = cursorRaw is String && cursorRaw.isNotEmpty
        ? cursorRaw
        : null;

    final items = list
        .map((e) {
          if (e is! Map) return null;
          return TimelineComment.fromJson(Map<String, dynamic>.from(e));
        })
        .whereType<TimelineComment>()
        .toList();

    return PaginatedResult<TimelineComment>(
      items: items,
      nextCursor: nextCursor,
    );
  }

  TimelineComment _parseComment(dynamic root, List<String> candidateKeys) {
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response shape");
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Missing data block");
    }
    for (final key in candidateKeys) {
      final raw = data[key];
      if (raw is Map) {
        return TimelineComment.fromJson(Map<String, dynamic>.from(raw));
      }
    }
    throw ApiFailure("Comment payload missing");
  }

  TimelineReel _parseReel(dynamic root, List<String> candidateKeys) {
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response shape");
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Missing data block");
    }
    for (final key in candidateKeys) {
      final raw = data[key];
      if (raw is Map) {
        return TimelineReel.fromJson(Map<String, dynamic>.from(raw));
      }
    }
    throw ApiFailure("Reel payload missing");
  }
}

final reelCommentRepositoryProvider = Provider<ReelCommentRepo>((ref) {
  return ReelCommentRepoImpl(
    networkService: ref.read(networkServiceProvider),
  );
});
