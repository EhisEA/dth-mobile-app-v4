import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/splash/view_model/splash_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

final _splashViewModel = ChangeNotifierProvider.autoDispose<SplashViewModel>((
  ref,
) {
  return SplashViewModel(
    ref.read(localCacheProvider),
    ref.read(appModulesStateProvider),
  );
});

class SplashView extends ConsumerStatefulWidget {
  static const String path = NavigatorRoutes.splash;
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with SingleTickerProviderStateMixin {
  static const List<String> _splashImages = [
    ImageAssets.splash1,
    ImageAssets.splash2,
    ImageAssets.splash3,
  ];

  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  /// Last slide stays opaque (no fade-out) until navigation.
  late final Animation<double> _lastSlideOpacityAnimation;
  late final Animation<double> _translateYAnimation;
  int _currentIndex = 0;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..addStatusListener(_onAnimationStatusChanged);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 30),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(_animationController);

    _lastSlideOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 65),
    ]).animate(_animationController);

    _translateYAnimation = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animationController.forward(from: 0);
      // Start fetching the modules in parallel with the splash animation
      // so the bottom nav has its tab list ready by the time we navigate.
      unawaited(ref.read(_splashViewModel).preloadModules());
    });
  }

  Future<void> _onAnimationStatusChanged(AnimationStatus status) async {
    if (status != AnimationStatus.completed || !mounted) return;
    if (_currentIndex < _splashImages.length - 1) {
      setState(() {
        _currentIndex += 1;
      });

      _animationController.forward(from: 0);
      return;
    }

    if (_hasNavigated) return;
    _hasNavigated = true;
    await ref.read(_splashViewModel).routeFromSplash();
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_onAnimationStatusChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff060606),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final isLast = _currentIndex == _splashImages.length - 1;
            final opacity = isLast
                ? _lastSlideOpacityAnimation.value
                : _opacityAnimation.value;
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, _translateYAnimation.value),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Image.asset(
              _splashImages[_currentIndex],
              height: 96,
              width: 233,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
