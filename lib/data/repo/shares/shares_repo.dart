/// Records share events to `POST /shares`. The backend uses this to keep each
/// model's `counts.shares` in sync regardless of which surface the share was
/// triggered from.
abstract class SharesRepo {
  /// Records that the authenticated user shared a model. [modelType] is one of
  /// `post`, `reel`, `livestream`, `comment`; [modelId] is the model's uid.
  ///
  /// Callers treat this as fire-and-forget — a failure here must not disrupt
  /// the share flow the user just completed.
  Future<void> recordShare({
    required String modelType,
    required String modelId,
  });
}
