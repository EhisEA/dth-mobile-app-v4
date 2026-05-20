class RoutingArgumentKey {
  static const String initialURl = "initialURl";
  static const String title = "title";
  static const String email = "email";
  static const String signature = "signature";
  static const String fullName = "fullName";
  static const String imageUrl = "imageUrl";

  /// [StoriesView] — backing reel uid. The reel detail (title, description,
  /// poster, video, like state, counts) is hydrated from [ReelsCache] —
  /// populated by the listing screens — and refreshed by the VM.
  static const String reelUid = "reelUid";

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

  /// [ConfirmationFlow] — [ConfirmationView] dismiss behaviour.
  static const String confirmationFlow = "confirmationFlow";

  /// Body copy for [ConfirmationView] when [confirmationSuccess] is true.
  static const String confirmationSuccessDescription =
      "confirmationSuccessDescription";

  /// Body copy for [ConfirmationView] when [confirmationSuccess] is false.
  static const String confirmationFailureDescription =
      "confirmationFailureDescription";

  /// Event uid when [confirmationFlow] is [ConfirmationFlow.ticket].
  static const String confirmationEventUid = "confirmationEventUid";

  /// Optional `Future<void> Function()` after successful ticket payment.
  /// In-memory navigation only — not serializable.
  static const String confirmationOnSuccess = "confirmationOnSuccess";

  /// Optional callback forwarded from [ShowView] → [PurchaseTicketsView].
  static const String onPurchaseSuccess = "onPurchaseSuccess";

  static const String callbackUrl = "callbackUrl";

  /// [AppWebView] — when false, hides the app-bar action that opens the URL
  /// in the system browser (e.g. signed support sessions must stay in-app).
  static const String showOpenInExternalBrowser = "showOpenInExternalBrowser";

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

  /// [ShowView] — event uid for `GET /api/events/{event_uid}`.
  static const String eventUid = "eventUid";

  /// [YourTicketsView] — [PurchasedTicket.toJson] for the selected group.
  static const String purchasedTicket = "purchasedTicket";

  /// @deprecated Use [purchasedTicket]. Legacy route map for [YourTicketsView].
  static const String yourTicketsArgs = "yourTicketsArgs";
}

abstract class OtpFlowArg {
  static const String login = "login";
  static const String register = "register";
}

/// Source flow for [ConfirmationView] (dismiss behaviour, navigation).
enum ConfirmationFlow {
  subscription,
  ticket;

  static ConfirmationFlow fromRouteValue(Object? value) {
    if (value is ConfirmationFlow) return value;
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return ConfirmationFlow.subscription;
    return ConfirmationFlow.values.firstWhere(
      (flow) => flow.name == raw,
      orElse: () => ConfirmationFlow.subscription,
    );
  }
}
