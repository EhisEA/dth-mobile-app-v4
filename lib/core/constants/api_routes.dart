import "package:dth_v4/flavor/flavor_config.dart";

/// Base URLs should be supplied via --dart-define in release builds to avoid
/// hardcoding. Example: flutter run --dart-define=STAGING_BASE_URL=https://dev.vent.africa/api
/// Fallbacks below are for local dev only; prefer env in CI/production.
class ApiRoute {
  static String get baseUrl => FlavorConfig.instance.baseUrl;

  static String get stagingBaseURL => const String.fromEnvironment(
    "STAGING_BASE_URL",
    defaultValue: "https://dth5.on-forge.com/api",
  );
  static String get prodBaseURL => const String.fromEnvironment(
    "PROD_BASE_URL",
    defaultValue: "https://dth5.on-forge.com/api",
  );

  /////AUTH
  static String get logout => "$baseUrl/auth/logout";
  static String get register => "$baseUrl/auth/register";
  static String get registerVerifyOtp => "$baseUrl/auth/register/verify-otp";
  static String get registerResendOtp => "$baseUrl/auth/register/resend-otp";
  static String get login => "$baseUrl/auth/login";
  static String get loginVerifyOtp => "$baseUrl/auth/login/verify-otp";
  static String get loginResendOtp => "$baseUrl/auth/login/resend-otp";
  static String get socialGoogle => "$baseUrl/auth/social/google";
  static String get countries => "$baseUrl/countries";

  ////APPLICATION
  static String get application => "$baseUrl/application";
  static String get applicationProcess => "$baseUrl/application/process";
  static String get applicantDashboard => "$baseUrl/applicant/dashboard";
  static String get applicantInterviewSlots =>
      "$baseUrl/applicant/interview-slots";
  static String get applicantInterviewBookings =>
      "$baseUrl/applicant/interview-bookings";
  static String get applicantInterviewBookingCurrent =>
      "$baseUrl/applicant/interview-bookings/current";
  static String get applicantSchedule => "$baseUrl/applicant/schedule";
  static String get applicantAuditionVideos =>
      "$baseUrl/applicant/audition-videos";

  ///SUBSCRIPTION
  static String get subscriptionPlans => "$baseUrl/subscription/plans";
  static String get subscriptionPurchase => "$baseUrl/subscription/purchase";

  static String paymentVerify(String reference) =>
      "$baseUrl/payment/verify/$reference";

  ///PROFILE
  static String get user => "$baseUrl/profile";
  static String get profilePhone => "$baseUrl/profile/phone";
  static String get profilePhoneSendOtp => "$baseUrl/profile/phone/send-otp";
  static String get profilePhoneVerifyOtp =>
      "$baseUrl/profile/phone/verify-otp";
  static String get profileUpdate => "$baseUrl/profile";
  static String get profileDeleteAccount => "$baseUrl/profile/delete-account";

  ///MODULES
  static String get mobileAppModules => "$baseUrl/mobile/app/modules";

  ///TIMELINE
  static String get timeline => "$baseUrl/timeline-posts";
  static String timelinePostDetail(String uid) =>
      "$baseUrl/timeline-posts/$uid";
  static String timelinePostReact(String uid) =>
      "$baseUrl/timeline-posts/$uid/react";
  static String timelinePostComments(String uid) =>
      "$baseUrl/timeline-posts/$uid/comments";
  static String timelineCommentReplies(String uid) =>
      "$baseUrl/timeline-posts/comments/$uid/replies";
  static String timelineCommentReact(String uid) =>
      "$baseUrl/timeline-posts/comments/$uid/react";
  static String get timelineReels => "$baseUrl/timeline-reels";
  static String timelineReelDetail(String uid) =>
      "$baseUrl/timeline-reels/$uid";
  static String timelineReelReact(String uid) =>
      "$baseUrl/timeline-reels/$uid/react";
  static String timelineReelComments(String uid) =>
      "$baseUrl/timeline-reels/$uid/comments";
  static String timelineReelCommentReact(String uid) =>
      "$baseUrl/timeline-reels/comments/$uid/react";

  ///POLLS
  static String get polls => "$baseUrl/polls";
  static String pollVote(String pollUid) => "$baseUrl/polls/$pollUid";

  ///EVENTS & TICKETS
  static String get eventsUpcoming => "$baseUrl/events/upcoming";
  static String get eventsBooked => "$baseUrl/events/booked";
  static String event(String eventUid) => "$baseUrl/events/$eventUid";
  static String get ticketsPurchase => "$baseUrl/tickets/purchase";

  /// SUPPORT
  static String get supportWebSession => "$baseUrl/support/web-session";
}
