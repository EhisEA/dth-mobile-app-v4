import "package:dth_v4/core/services/deep_link_service.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:share_plus/share_plus.dart";

/// Bridges [DeepLinkService] link creation with [SharePlus] so each share UI
/// is a single call. Failure (null URL from the source) surfaces via flushbar
/// instead of falling through to a contentless share sheet.
class LinkShareHelper {
  LinkShareHelper._();

  static const _logger = AppLogger(LinkShareHelper);
  static const _failureTitle = "Share";
  static const _failureMessage =
      "Couldn't generate a share link. Please try again.";

  static Future<void> sharePost({
    required String postUid,
    String title = "",
    String description = "",
    String imageUrl = "",
  }) {
    return _shareWith(
      () => DeepLinkService.instance.createTimelineLink(
        postId: postUid,
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
      subject: title,
    );
  }

  static Future<void> shareComment({
    required String commentUid,
    String title = "",
    String description = "",
    String imageUrl = "",
  }) {
    return _shareWith(
      () => DeepLinkService.instance.createCommentLink(
        commentId: commentUid,
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
      subject: title,
    );
  }

  static Future<void> shareReel({
    required String reelUid,
    String title = "",
    String description = "",
    String imageUrl = "",
  }) {
    return _shareWith(
      () => DeepLinkService.instance.createReelLink(
        reelUid: reelUid,
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
      subject: title,
    );
  }

  static Future<void> shareEvent({
    required String eventUid,
    String title = "",
    String description = "",
    String imageUrl = "",
  }) {
    return _shareWith(
      () => DeepLinkService.instance.createEventLink(
        eventId: eventUid,
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
      subject: title,
    );
  }

  static Future<void> shareReferral({
    required String code,
    String title = "",
    String description = "",
    String imageUrl = "",
  }) {
    return _shareWith(
      () => DeepLinkService.instance.createReferralLink(
        code: code,
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
      subject: title,
    );
  }

  static Future<void> _shareWith(
    Future<String?> Function() createLink, {
    required String subject,
  }) async {
    try {
      final url = await createLink();
      if (url == null || url.isEmpty) {
        _logger.e("Share link returned null");
        DthFlushBar.instance.showError(
          title: _failureTitle,
          message: _failureMessage,
        );
        return;
      }
      await SharePlus.instance.share(
        ShareParams(text: url, subject: subject.isEmpty ? null : subject),
      );
    } catch (err, st) {
      _logger.e("Share failed: $err\n$st");
      DthFlushBar.instance.showError(
        title: _failureTitle,
        message: _failureMessage,
      );
    }
  }
}
