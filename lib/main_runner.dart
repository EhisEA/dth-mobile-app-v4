import "dart:async";

import "package:dth_v4/app/app.dart";
import "package:dth_v4/core/core.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppVersion.initialize();

  // Push setup runs only when the flavor's main_*.dart has already called
  // Firebase.initializeApp. Avoids a [core/no-app] crash on flavors that
  // haven't shipped a Firebase config yet — prod today, until a
  // firebase_options_prod.dart is wired up there.
  if (Firebase.apps.isNotEmpty) {
    // `firebaseMessagingBackgroundHandler` is a top-level function (see
    // push_notification_service.dart) — required by FCM so the bg isolate
    // can resolve it via PluginUtilities. A static class method does not work.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    unawaited(PushNotificationService.instance.initialise());
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
    ],
  );

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}
