/// Branch reserved keys read from incoming session data.
class BranchSessionKey {
  static const String clickedBranchLink = "+clicked_branch_link";

  /// Branch's resolved deep-link path. Populated from the link's
  /// [BranchControlParam.deeplinkPath] — but not always present in the
  /// session payload, so parsing falls back to [deeplinkPathParam].
  static const String deepLinkPath = "+deep_link_path";

  /// The raw `$deeplink_path` control param echoed back in the session. Used
  /// as a fallback when [deepLinkPath] is absent.
  static const String deeplinkPathParam = "\$deeplink_path";
  static const String canonicalIdentifier = "\$canonical_identifier";
}

/// Branch control-param keys set when creating a link.
class BranchControlParam {
  /// Surfaces as [BranchSessionKey.deepLinkPath] on the receiving side.
  static const String deeplinkPath = "\$deeplink_path";
}

/// Paths emitted as `+deep_link_path` for each link type. The router matches on these.
class DeepLinkPaths {
  static const String referral = "/referral";
  static const String timeline = "/timeline";
  static const String comment = "/comment";
  static const String event = "/event";
  static const String reel = "/reel";
  static const String livestream = "/livestream";
}

/// Custom payload keys carried inside a link's metadata.
class DeepLinkParams {
  static const String referralCode = "referral_code";
  static const String postId = "post_id";
  static const String commentId = "comment_id";
  static const String eventId = "event_id";
  static const String reelUid = "reel_uid";
  static const String livestreamUid = "livestream_uid";
}

/// Branch link analytics labels.
class DeepLinkChannel {
  static const String app = "app";
}

class DeepLinkFeature {
  static const String referral = "referral";
  static const String sharing = "sharing";
}
