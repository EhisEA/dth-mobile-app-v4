import "package:dth_v4/core/utils/utils.dart";
import "package:dth_v4/data/state/device_info_state.dart";
import "package:flutter/foundation.dart";

class AppConstants {
  static const String appUpdateRequired = "app-update-required";
}

class AppLink {
  static const String iosStoreLink =
      "https://apps.apple.com/us/app/de9jaspirit-talent-hunt/id1624305734";
  static const String androidStoreLink =
      "https://play.google.com/store/apps/details?id=com.dth.dth";

  static const String vent = "https://vent.africa";
  static const String privacyPolicy = "https://dth.ng/privacy";
  static const String termsAndConditions = "https://dth.ng/terms";
  static const String dthWebsite = "https://dth.ng";
}

class AppInfo {
  // static String get appVersion => "";
  static String get deviceOS {
    if (kIsWeb) return "web";
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return "ios";
      case TargetPlatform.android:
        return "android";
      default:
        return "UNSET";
    }
  }

  /// Gets the actual app version from the device
  // static Future<String> getAppVersion() async {
  //   return await AppVersion.getAppVersion();
  // }

  /// Gets the app version synchronously (returns cached value or fallback)
  static String getAppVersionSync() {
    return AppVersion.getAppVersionSync();
  }

  static Future<Map<String, dynamic>> payload(
    DeviceInfoState deviceInfo,
  ) async {
    return {
      "x-Device-Name": await deviceInfo.getDeviceName(),
      "x-Device-OS": deviceOS,
      "x-App-Version": getAppVersionSync(),
    };
  }
}
