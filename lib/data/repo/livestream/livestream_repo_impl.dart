import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class LivestreamRepoImpl implements LivestreamRepo {
  LivestreamRepoImpl({required NetworkService networkService})
    : _networkService = networkService;

  final NetworkService _networkService;

  @override
  Future<Livestream?> fetchActive() async {
    final response = await _networkService.get(ApiRoute.livestreams);
    return _parseLivestream(response.data, allowNull: true);
  }

  @override
  Future<Livestream> toggleReaction(String uid) async {
    final response = await _networkService.post(
      ApiRoute.livestreamReact(uid),
    );
    final parsed = _parseLivestream(response.data, allowNull: false);
    if (parsed == null) {
      throw ApiFailure("Livestream payload missing");
    }
    return parsed;
  }

  /// Both `GET /livestreams` and `POST /livestreams/:uid/react` return
  /// `{ data: { livestream: { ... } | null } }`. The `null` case is only
  /// expected on the GET when there's no active stream — toggleReaction
  /// passes `allowNull: false` so a null payload there surfaces as an error.
  Livestream? _parseLivestream(dynamic root, {required bool allowNull}) {
    if (root is! Map<String, dynamic>) {
      throw ApiFailure("Invalid response shape");
    }
    final data = root["data"];
    if (data is! Map<String, dynamic>) {
      throw ApiFailure("Missing data block");
    }
    final raw = data["livestream"];
    if (raw == null) {
      if (allowNull) return null;
      throw ApiFailure("Livestream payload missing");
    }
    if (raw is! Map) {
      throw ApiFailure("Livestream payload malformed");
    }
    return Livestream.fromJson(Map<String, dynamic>.from(raw));
  }
}

final livestreamRepositoryProvider = Provider<LivestreamRepo>((ref) {
  return LivestreamRepoImpl(networkService: ref.read(networkServiceProvider));
});
