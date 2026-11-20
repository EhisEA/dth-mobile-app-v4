/// Copy for the "running low" popup, sent by the backend as
/// `voting_credit_info.running_low`. `message` may contain inline `<b>`, `<u>`
/// or `<i>` tags (e.g. `<b>1200</b>`) to emphasise parts of the text.
class VotingRunningLowPrompt {
  const VotingRunningLowPrompt({
    required this.title,
    required this.message,
    required this.ctaLabel,
  });

  final String title;
  final String message;
  final String ctaLabel;

  static const _defaultTitle = "Your Voting Credits Are Running Low";
  static const _defaultMessage =
      "Top up now so you don't miss the chance to save your favourite "
      "contestant.";
  static const _defaultCtaLabel = "Top up now";

  static const fallback = VotingRunningLowPrompt(
    title: _defaultTitle,
    message: _defaultMessage,
    ctaLabel: _defaultCtaLabel,
  );

  /// `false` / null → null (not running low); an object → its copy, with
  /// defaults for any missing field; a bare `true` → [fallback] copy.
  static VotingRunningLowPrompt? tryParse(dynamic value) {
    if (value is Map) {
      return VotingRunningLowPrompt(
        title: _string(value["title"], _defaultTitle),
        message: _string(value["message"], _defaultMessage),
        ctaLabel: _string(value["cta_label"], _defaultCtaLabel),
      );
    }
    if (value == true) return fallback;
    return null;
  }

  static String _string(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? "";
    return text.isEmpty ? fallback : text;
  }
}
