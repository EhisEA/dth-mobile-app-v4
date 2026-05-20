import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/splash/views/splash_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Future.wait([
      PreLoadImage.loadImg(context, ImageAssets.subscriptionBg),
      PreLoadImage.loadImg(context, ImageAssets.userBg),
      PreLoadImage.loadImg(context, ImageAssets.contestantBg),
      PreLoadImage.loadImg(context, ImageAssets.applicantBg),
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [RouteLifecycleObserver.routeObserver],
      navigatorKey: MobileNavigationService.instance.navigatorKey,
      builder: (context, widget) {
        Widget child = Navigator(
          key: DthFlushBar.navigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => FlushBarLayer(child: widget!),
          ),
        );

        if (kIsWeb) {
          final data = MediaQuery.of(context);
          final clampedWidth = data.size.width.clamp(0.0, 650.0);
          child = Center(
            child: SizedBox(
              width: clampedWidth,
              child: MediaQuery(
                data: data.copyWith(size: Size(clampedWidth, data.size.height)),
                child: child,
              ),
            ),
          );
        }

        // Unfocus on pointer down without a TapGestureRecognizer — a root
        // [GestureDetector] competes in the gesture arena with embedded
        // players (e.g. YouTube) and can break their play/pause controls.
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
      theme: AppThemeData.lightTheme,
      themeMode: ThemeMode.light,
      onGenerateRoute: AppRouter.generateRoute,
      home: const SplashView(),
    );
  }
}
