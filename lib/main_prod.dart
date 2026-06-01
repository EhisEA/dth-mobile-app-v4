import "dart:async";
import "package:dth_v4/core/constants/api_routes.dart";
import "package:dth_v4/firebase_options_prod.dart";
import "package:dth_v4/flavor/flavor_config.dart";
import "package:dth_v4/main_runner.dart" as runner;
import "package:firebase_core/firebase_core.dart";
import "package:flutter/widgets.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig(
    flavor: Flavor.prod,
    title: Flavor.prod.title,
    baseUrl: ApiRoute.prodBaseURL,
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  unawaited(runner.main());
}
