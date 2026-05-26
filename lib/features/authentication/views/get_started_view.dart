import 'dart:async';

import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/state/app_modules_state.dart';
import 'package:dth_v4/features/app_web_view/app_web_view.dart';
import 'package:dth_v4/features/authentication/view_model/get_started_view_model.dart';
import 'package:dth_v4/features/authentication/views/create_account_view.dart';
import 'package:dth_v4/features/bottomNavBar/bottom_nav_bar.dart';
import 'package:dth_v4/widgets/text/text.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class GetStartedView extends ConsumerStatefulWidget {
  const GetStartedView({super.key});

  static const String path = NavigatorRoutes.getStarted;

  @override
  ConsumerState<GetStartedView> createState() => _GetStartedViewState();
}

class _GetStartedViewState extends ConsumerState<GetStartedView> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;
  Timer? _backgroundTimer;
  int _currentBackgroundIndex = 0;
  static const List<String> _backgroundImages = [
    ImageAssets.authBg1,
    ImageAssets.authBg2,
    ImageAssets.authBg3,
  ];

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _onTermsPressed;
    _privacyTap = TapGestureRecognizer()..onTap = _onPrivacyPressed;
    _startBackgroundCarousel();
  }

  void _startBackgroundCarousel() {
    _backgroundTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _currentBackgroundIndex =
            (_currentBackgroundIndex + 1) % _backgroundImages.length;
      });
    });
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _onTermsPressed() {
    HapticFeedback.lightImpact();
    MobileNavigationService.instance.navigateTo(
      AppWebView.path,
      extra: {
        RoutingArgumentKey.title: "Terms & Conditions",
        RoutingArgumentKey.initialURl: AppLink.termsAndConditions,
      },
    );
  }

  void _onPrivacyPressed() {
    HapticFeedback.lightImpact();
    MobileNavigationService.instance.navigateTo(
      AppWebView.path,
      extra: {
        RoutingArgumentKey.title: "Privacy Policy",
        RoutingArgumentKey.initialURl: AppLink.privacyPolicy,
      },
    );
  }

  Future<void> _onGooglePressed() async {
    HapticFeedback.lightImpact();
    final model = ref.read(getStartedViewModelProvider);
    final success = await model.signInWithGoogle();
    if (!mounted || !success) return;
    MobileNavigationService.instance.navigateAndClearStack(BottomNavBar.path);
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(getStartedViewModelProvider);
    final googleEnabled = ref
            .watch(appModulesStateProvider)
            .appModules
            .value
            ?.googleLoginEnabled ==
        true;
    final theme = Theme.of(context);
    final bodyColor = AppColors.white;
    const linkColor = AppColors.primary;
    final baseStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: bodyColor,
          fontSize: 12,
          height: 1.45,
        ) ??
        TextStyle(color: bodyColor, fontSize: 12, height: 1.45);
    final linkStyle = AppTextStyle.regular.copyWith(
      color: linkColor,
      fontSize: 12,
    );
    final blackStyle = AppTextStyle.regular.copyWith(
      color: AppColors.white,
      fontSize: 12,
    );

    Widget svgIcon(String asset, {double size = 16}) {
      return SvgPicture.asset(asset, width: size, height: size);
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: Image.asset(
              height: double.infinity,
              width: double.infinity,
              _backgroundImages[_currentBackgroundIndex],
              key: ValueKey(_backgroundImages[_currentBackgroundIndex]),
              fit: BoxFit.fill,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Gap.h14,
                  Center(
                    child: Image.asset(
                      ImageAssets.logoWhite,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AppText.bold(
                    'Welcome to DTH 5',
                    fontSize: 28,
                    color: const Color(0xffC2FFE0),
                    letterSpacing: -0.4,
                  ),
                  Gap.h6,
                  AppText.bold(
                    'Where stars are made'.toUpperCase(),
                    color: AppColors.white,
                    fontSize: 8,
                    letterSpacing: 2.0,
                  ),
                  Gap.h6,
                  Image.asset(
                    ImageAssets.line,
                    width: 90.91,
                    fit: BoxFit.cover,
                  ),
                  Gap.h8,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppText.regular(
                      'Apply to audition, watch live performances, and vote for your favorite contestants.',
                      color: const Color(0xffF4F4F4),
                      fontSize: 14,
                      letterSpacing: -0.4,
                      centered: true,
                    ),
                  ),
                  Gap.h24,
                  AppButton.primary(
                    text: 'Continue with email',
                    enabled: !model.isBaseBusy,
                    press: () {
                      MobileNavigationService.instance.push(
                        CreateAccountView.path,
                      );
                    },
                  ),
                  if (googleEnabled) ...[
                    Gap.h12,
                    AppButton.onBorder(
                      text: 'Continue with Google',
                      textColor: AppColors.white,
                      borderColor: AppColors.primary,
                      prefixIcon: svgIcon(SvgAssets.googleLogo),
                      isLoading: model.isBaseBusy,
                      enabled: !model.isBaseBusy,
                      press: _onGooglePressed,
                    ),
                  ],
                  // Gap.h12,
                  // AppButton.onBorder(
                  //   text: 'Continue with Apple',
                  //   textColor: AppColors.black,
                  //   borderColor: AppColors.primary,
                  //   prefixIcon: svgIcon(SvgAssets.appleLogo),
                  //   enabled: !model.isBaseBusy,
                  //   press: () {
                  //     MobileNavigationService.instance.navigateAndClearStack(
                  //       BottomNavBar.path,
                  //     );
                  //   },
                  // ),
                  Gap.h24,
                  Text.rich(
                    TextSpan(
                      style: baseStyle,
                      children: [
                        const TextSpan(text: 'By clicking '),
                        TextSpan(text: '"Continue" ', style: blackStyle),
                        const TextSpan(text: 'you acknowledge and agree to '),
                        TextSpan(
                          text: "DTH's Terms & Conditions",
                          style: linkStyle,
                          recognizer: _termsTap,
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy.',
                          style: linkStyle,
                          recognizer: _privacyTap,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Gap.h16,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
