import "package:dth_v4/data/data.dart";

/// Whether the enforced phone-verification bottom sheet should appear.
bool shouldEnforcePhoneVerification(UserModel user) {
  if (user.isPhoneVerified) return false;
  final iso = user.isoCode.trim().toUpperCase();
  if (iso.isEmpty) {
    final phone = user.phoneNumber.trim();
    if (phone.startsWith("+234") || phone.startsWith("234")) return true;
    return true;
  }
  if (iso == "NG") return true;
  return false;
}
