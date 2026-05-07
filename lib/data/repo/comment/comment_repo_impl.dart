import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class CommentRepoImpl implements CommentRepo {
  CommentRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<PaginatedResult<TimelineComment>> listComments(
    String postUid, {
    String? cursor,
    CommentSort sort = CommentSort.latest,
  }) async {
    final response = await _networkService.get(
      ApiRoute.timelinePostComments(postUid),
      queryParams: _listParams(cursor: cursor, sort: sort),
    );
    return _parsePaginated(response.data, listKey: "comments");
  }

  @override
  Future<PaginatedResult<TimelineComment>> listReplies(
    String commentUid, {
    String? cursor,
    CommentSort sort = CommentSort.latest,
  }) async {
    final response = await _networkService.get(
      ApiRoute.timelineCommentReplies(commentUid),
      queryParams: _listParams(cursor: cursor, sort: sort),
    );
    return _parsePaginated(response.data, listKey: "replies");
  }

  @override
  Future<TimelineComment> createComment(String postUid, String body) async {
    final response = await _networkService.post(
      ApiRoute.timelinePostComments(postUid),
      data: {"description": body},
    );
    return _parseSingle(response.data, ["comment"]);
  }

  @override
  Future<TimelineComment> createReply(String commentUid, String body) async {
    final response = await _networkService.post(
      ApiRoute.timelineCommentReplies(commentUid),
      data: {"description": body},
    );
    // API currently returns { data: { replies: {...single object...} } } —
    // accept either shape so a future backend cleanup ("reply") doesn't break us.
    return _parseSingle(response.data, ["reply", "replies"]);
  }

  @override
  Future<TimelineComment> toggleReaction(String commentUid) async {
    final response = await _networkService.post(
      ApiRoute.timelineCommentReact(commentUid),
    );
    return _parseSingle(response.data, ["comment"]);
  }

  Map<String, dynamic>? _listParams({String? cursor, CommentSort? sort}) {
    final params = <String, dynamic>{};
    if (cursor != null && cursor.isNotEmpty) params["cursor"] = cursor;
    if (sort != null) params["sort"] = sort.apiValue;
    return params.isEmpty ? null : params;
  }

  /// Parses the cursor-paginated envelope:
  /// `{ data: { <listKey>: { data: [...], next_cursor: "...", ... } } }`
  ///
  /// Falls back to an empty result if the envelope is missing — defensive
  /// against partial backend rollouts where one list endpoint hasn't been
  /// migrated to the new shape yet.
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

  TimelineComment _parseSingle(dynamic root, List<String> candidateKeys) {
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
}

final commentRepositoryProvider = Provider<CommentRepo>((ref) {
  return CommentRepoImpl(networkService: ref.read(networkServiceProvider));
});
