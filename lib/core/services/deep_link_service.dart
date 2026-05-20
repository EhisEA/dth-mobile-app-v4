import "dart:async";

import "package:dth_v4/core/constants/deep_linking_keys.dart";
import "package:dth_v4/core/services/branch_service.dart";
import "package:flutter_utils/flutter_utils.dart";

class DeepLink {
  const DeepLink({required this.path, required this.data});

  /// Value of `+deep_link_path` in the Branch session, e.g. "/referral".
  final String? path;

  /// Full session payload — callers read whatever typed value they need.
  final Map<dynamic, dynamic> data;
}

abstract class DeepLinkSource {
  Future<void> initialise({bool enableLogging = false});
  Stream<DeepLink> get links;

  /// Generic short-link creator. Returns the short URL or null on failure.
  Future<String?> createLink({
    required String canonicalIdentifier,
    required String feature,
    required String path,
    String channel,
    String campaign,
    String title,
    String description,
    String imageUrl,
    Map<String, dynamic> data,
  });

  Future<void> dispose();
}

class DeepLinkService {
  DeepLinkService._(this._source);

  static final DeepLinkService instance = DeepLinkService._(
    BranchService.instance,
  );

  final DeepLinkSource _source;
  static const _logger = AppLogger(DeepLinkService);

  final _controller = StreamController<DeepLink>.broadcast();
  StreamSubscription<DeepLink>? _sub;

  Stream<DeepLink> get links => _controller.stream;

  Future<void> initialise({bool enableLogging = false}) async {
    await _source.initialise(enableLogging: enableLogging);
    _sub = _source.links.listen(
      (link) {
        _logger.i("DeepLink received: path=${link.path} data=${link.data}");
        _controller.add(link);
      },
      onError: (Object err) => _logger.e("DeepLink source error: $err"),
    );
  }

  Future<String?> createReferralLink({
    required String code,
    String title = "",
    String description = "",
    String imageUrl = "",
  }) {
    return _source.createLink(
      canonicalIdentifier: "referral/$code",
      feature: DeepLinkFeature.referral,
      path: DeepLinkPaths.referral,
      title: title,
      description: description,
      imageUrl: imageUrl,
      data: {DeepLinkParams.referralCode: code},
    );
  }

  Future<String?> createTimelineLink({
    required String postId,
    String title = "",
    String description = "",
    String imageUrl = "",
  }) {
    return _source.createLink(
      canonicalIdentifier: "timeline/$postId",
      feature: DeepLinkFeature.sharing,
      path: DeepLinkPaths.timeline,
      title: title,
      description: description,
      imageUrl: imageUrl,
      data: {DeepLinkParams.postId: postId},
    );
  }

  Future<String?> createCommentLink({
    required String postId,
    required String commentId,
    String title = "",
    String description = "",
    String imageUrl = "",
  }) {
    return _source.createLink(
      canonicalIdentifier: "comment/$commentId",
      feature: DeepLinkFeature.sharing,
      path: DeepLinkPaths.comment,
      title: title,
      description: description,
      imageUrl: imageUrl,
      data: {
        DeepLinkParams.postId: postId,
        DeepLinkParams.commentId: commentId,
      },
    );
  }

  Future<String?> createEventLink({
    required String eventId,
    String title = "",
    String description = "",
    String imageUrl = "",
  }) {
    return _source.createLink(
      canonicalIdentifier: "event/$eventId",
      feature: DeepLinkFeature.sharing,
      path: DeepLinkPaths.event,
      title: title,
      description: description,
      imageUrl: imageUrl,
      data: {DeepLinkParams.eventId: eventId},
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _source.dispose();
    await _controller.close();
  }
}
