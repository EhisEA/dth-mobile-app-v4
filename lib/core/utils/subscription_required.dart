import "package:flutter_utils/flutter_utils.dart";

/// True when the API responded with 403 and `event: subscription_required`.
bool isSubscriptionRequiredFailure(Object? error) {
  if (error is! ApiFailure || error.statusCode != 403) return false;
  return error.event?.trim().toLowerCase() == "subscription_required";
}
