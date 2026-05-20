import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class PostRepoImpl implements PostRepo {
  PostRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<TimelinePost> fetchPost(String uid) async {
    final response = await _networkService.get(
      ApiRoute.timelinePostDetail(uid),
    );
    return _parsePost(response.data);
  }

  @override
  Future<TimelinePost> toggleReaction(String uid) async {
    final response = await _networkService.post(
      ApiRoute.timelinePostReact(uid),
    );
    return _parsePost(response.data);
  }

  TimelinePost _parsePost(dynamic root) {
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response shape");
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Missing data block");
    }
    final post = data["post"];
    if (post is! Map) {
      throw ApiFailure("Post not found");
    }
    return TimelinePost.fromJson(Map<String, dynamic>.from(post));
  }
}

final postRepositoryProvider = Provider<PostRepo>((ref) {
  return PostRepoImpl(networkService: ref.read(networkServiceProvider));
});
