import "dart:async";

import "package:dth_v4/app/app.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/flavor/flavor_config.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppVersion.initialize();
  await DeepLinkService.instance.initialise(
    enableLogging: FlavorConfig.instance.isDev,
  );

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
