import "package:another_flushbar/flushbar.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";

class DthFlushBar {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final DthFlushBar instance = DthFlushBar._();
  DthFlushBar._();

  void showSuccess({
    required String message,
    required String title,
    Duration? duration,
    FlushbarPosition? position = FlushbarPosition.TOP,
  }) {
    Flushbar<dynamic>(
      flushbarPosition: position ?? FlushbarPosition.TOP,
      duration: duration ?? const Duration(seconds: 5),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 1250),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      boxShadows: [lightFlushBarShadow],
      message: message,
      messageText: _FlushBarWidget(
        title: title,
        message: message,
        icon: SvgAssets.verifyActive,
      ),
    ).show(navigatorKey.currentContext!);
  }

  /// Use after writing to the clipboard. Skips the in-app success bar on
  /// Android, where the OS already surfaces its own copy confirmation.
  void showCopySuccess({
    required String message,
    required String title,
    Duration? duration,
    FlushbarPosition? position = FlushbarPosition.TOP,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) return;
    showSuccess(
      message: message,
      title: title,
      duration: duration,
      position: position,
    );
  }

  void showError({
    required String message,
    required String title,
    Duration? duration,
    FlushbarPosition? position = FlushbarPosition.TOP,
  }) {
    Flushbar<dynamic>(
      flushbarPosition: position ?? FlushbarPosition.TOP,
      duration: duration ?? const Duration(seconds: 5),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 1250),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      boxShadows: [lightFlushBarShadow],
      message: message,
      messageText: _FlushBarWidget(
        title: title,
        message: message,
        icon: SvgAssets.verifyActive,
        iconColor: Colors.red,
        showDismiss: true,
      ),
    ).show(navigatorKey.currentContext!);
  }

  void showGeneric({
    required String message,
    required String title,
    Duration? duration,
    FlushbarPosition? position = FlushbarPosition.TOP,
  }) {
    Flushbar<dynamic>(
      flushbarPosition: position ?? FlushbarPosition.TOP,
      duration: duration ?? const Duration(seconds: 5),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 1250),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.zero,
      boxShadows: [lightFlushBarShadow],
      message: message,
      messageText: _FlushBarWidget(
        title: title,
        message: message,
        icon: SvgAssets.verifyActive,
        showDismiss: true,
      ),
    ).show(navigatorKey.currentContext!);
  }
}

class FlushBarLayer extends StatefulWidget {
  final Widget child;

  const FlushBarLayer({super.key, required this.child});

  @override
  State<FlushBarLayer> createState() => _FlushBarLayerState();
}

class _FlushBarLayerState extends State<FlushBarLayer> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

BoxShadow get lightFlushBarShadow => BoxShadow(
  color: const Color(0xff354A68).withValues(alpha: 0.14),
  blurRadius: 48,
  offset: const Offset(10, 10),
  spreadRadius: 0,
);

class _FlushBarWidget extends StatelessWidget {
  const _FlushBarWidget({
    required this.title,
    required this.message,
    this.showDismiss = false,
    required this.icon,
    this.iconColor,
  });
  final String icon;
  final Color? iconColor;
  final String message;
  final String title;
  final bool? showDismiss;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          left: 12,
          top: 12,
          right: 14,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(
                iconColor ?? AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
            Gap.w8,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.medium(
                      title,
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                    Gap.h4,
                    AppText.regular(
                      message,
                      color: const Color(0xff666666),
                      fontSize: 10,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
            Gap.w16,
            if (showDismiss == true) ...[
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.primary,
                  ),
                  child: AppText.regular(
                    "Dismiss",
                    color: AppColors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
