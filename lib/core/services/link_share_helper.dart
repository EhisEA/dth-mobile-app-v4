import "dart:async";

import "package:dth_v4/core/services/deep_link_service.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:share_plus/share_plus.dart";

/// Records a share to the backend. Returns once the call resolves; callers
/// invoke it fire-and-forget so backend latency/failure never blocks the share
/// sheet. Wired in [LinkShareHelper.bootstrap] at app start.
typedef ShareRecorder =
    Future<void> Function({required String modelType, required String modelId});

/// `model_type` values accepted by `POST /shares`. Referrals share links too,
/// but the backend does not track them, so they pass no type and skip the
/// record call.
abstract class ShareModelType {
  static const post = "post";
  static const reel = "reel";
  static const livestream = "livestream";
  static const comment = "comment";
  static const event = "event";
}

/// Bridges [DeepLinkService] link creation with [SharePlus] so each share UI
/// is a single call. Failure (null URL from the source) surfaces via flushbar
/// instead of falling through to a contentless share sheet.
///
/// When a [ShareRecorder] has been wired via [bootstrap] and the share carries
/// a backend-tracked [ShareModelType], the share is also recorded to
/// `POST /shares` so the model's `counts.shares` stays in sync.
class LinkShareHelper {
  LinkShareHelper._();

  static const _logger = AppLogger(LinkShareHelper);
  static const _failureTitle = "Share";
  static const _failureMessage =
      "Couldn't generate a share link. Please try again.";

  static ShareRecorder? _recorder;

  /// Wires the backend share recorder. Call once at app start (see
  /// `main_runner.dart`). No-op shares (missing recorder) simply skip the
  /// record call.
  static void bootstrap(ShareRecorder recorder) {
    _recorder = recorder;
  }

  static Future<void> sharePost({
    required String postUid,
    String title = "",
    String description = "",
    String imageUrl = "",
    VoidCallback? onShared,
  }) {
    return _shareWith(
      () => DeepLinkService.instance.createTimelineLink(
        postId: postUid,
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
      subject: title,
      modelType: ShareModelType.post,
      modelId: postUid,
      onShared: onShared,
    );
  }

  static Future<void> shareComment({
    required String commentUid,
    String title = "",
    String description = "",
    String imageUrl = "",
    VoidCallback? onShared,
  }) {
    return _shareWith(
      () => DeepLinkService.instance.createCommentLink(
        commentId: commentUid,
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
      subject: title,
      modelType: ShareModelType.comment,
      modelId: commentUid,
      onShared: onShared,
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
      modelType: ShareModelType.reel,
      modelId: reelUid,
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
      modelType: ShareModelType.event,
      modelId: eventUid,
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
    String? modelType,
    String? modelId,
    VoidCallback? onShared,
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
      final result = await SharePlus.instance.share(
        ShareParams(text: url, subject: subject.isEmpty ? null : subject),
      );
      // Only count a share the user actually completed — dismissing the sheet
      // (or an unavailable target) shouldn't bump the count or hit the API.
      if (result.status == ShareResultStatus.success) {
        _recordShare(modelType, modelId);
        onShared?.call();
      }
    } catch (err, st) {
      _logger.e("Share failed: $err\n$st");
      DthFlushBar.instance.showError(
        title: _failureTitle,
        message: _failureMessage,
      );
    }
  }

  /// Reports the share to the backend, fire-and-forget. Skips when the share
  /// isn't backend-tracked (e.g. events, referrals) or the recorder hasn't been
  /// wired. A failed record is logged but never surfaced — the user already
  /// shared successfully.
  static void _recordShare(String? modelType, String? modelId) {
    if (modelType == null || modelId == null || modelId.isEmpty) return;
    final recorder = _recorder;
    if (recorder == null) {
      _logger.w("Share recorder not bootstrapped; skipping record");
      return;
    }
    unawaited(
      recorder(modelType: modelType, modelId: modelId).catchError(
        (Object err, StackTrace st) =>
            _logger.w("Failed to record share ($modelType:$modelId): $err"),
      ),
    );
  }
}
