/// Response from `POST /profile/phone`.
class ProfilePhoneSubmitResult {
  const ProfilePhoneSubmitResult({
    required this.event,
    required this.message,
    this.signature,
  });

  static const String eventVerificationRequired =
      "phone-number-verification-required";

  static const String eventDefault = "default";

  final String event;
  final String message;
  final String? signature;

  bool get requiresVerification => event == eventVerificationRequired;

  factory ProfilePhoneSubmitResult.fromResponseRoot(Map<String, dynamic> root) {
    final event = root["event"] as String? ?? "";
    final message = root["message"] as String? ?? "";
    String? signature;
    final data = root["data"];
    if (data is Map<String, dynamic>) {
      final sig = data["signature"];
      if (sig is String && sig.isNotEmpty) signature = sig;
    }
    return ProfilePhoneSubmitResult(
      event: event,
      message: message,
      signature: signature,
    );
  }
}
