class RoutingArgumentKey {
  static const String initialURl = "initialURl";
  static const String title = "title";
  static const String email = "email";
  static const String signature = "signature";
  static const String fullName = "fullName";
  static const String imageUrl = "imageUrl";

  /// [PostDetailView] — uid of the timeline post to load.
  static const String postUid = "postUid";

  /// [CommentThreadView] — uid of the parent comment to load.
  static const String commentUid = "commentUid";

  /// `"login"` or `"register"` for [VerifyOtpView] / [VerifyOtpViewModel].
  static const String otpFlow = "otpFlow";

  static const String applicationDraft = "applicationDraft";
  static const String user = "user";

  /// `bool` — subscription checkout simulation ([ConfirmationView]).
  static const String confirmationSuccess = "confirmationSuccess";

  static const String callbackUrl = "callbackUrl";

  /// [ShowView] — full event location line (quick info row).
  static const String eventLocation = "eventLocation";

  /// [ShowView] — clock line in quick info (e.g. `9 Sept., 2026 02:30AM`).
  static const String eventDateTimeDisplay = "eventDateTimeDisplay";

  /// [ShowView] — long “About event” copy (use `\n\n` between paragraphs).
  static const String aboutEventBody = "aboutEventBody";

  static const String eventDetailDate = "eventDetailDate";
  static const String eventDetailTime = "eventDetailTime";
  static const String eventDetailVenue = "eventDetailVenue";

  /// [ShowView] — e.g. `546` or `(546 available)`; shown under CTA.
  static const String ticketsAvailable = "ticketsAvailable";

  /// [ShowView] — badge label, default `Upcoming`.
  static const String eventStatusLabel = "eventStatusLabel";
}

abstract class OtpFlowArg {
  static const String login = "login";
  static const String register = "register";
}
