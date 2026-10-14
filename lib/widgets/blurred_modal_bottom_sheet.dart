import "dart:ui";

import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";

/// Opens a modal bottom sheet with a **blurred, dimmed** scrim (instead of a
/// flat dark [ModalBarrier]). Taps on the scrim pop the sheet when
/// [isDismissible] is true.
Future<T?> showBlurredModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext sheetContext) builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool useSafeArea = true,
  bool enableDrag = true,
  bool? isCentered,

  /// Outer inset around the white sheet (e.g. floating product detail).
  EdgeInsetsGeometry? margin,

  /// Corners of the white sheet. Defaults to top-only 24, or full 28 when
  /// [margin] is set and this is omitted.
  BorderRadiusGeometry? borderRadius,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: false,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    sheetAnimationStyle: sheetAnimationStyle,
    requestFocus: requestFocus,
    builder: (modalContext) => _BlurredBottomSheetFrame(
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      isCentered: isCentered == true,
      margin: margin,
      borderRadius: borderRadius,
      child: builder(modalContext),
    ),
  );
}

class _BlurredBottomSheetFrame extends StatelessWidget {
  const _BlurredBottomSheetFrame({
    required this.child,
    required this.useSafeArea,
    required this.isDismissible,
    this.isCentered = false,
    this.margin,
    this.borderRadius,
  });

  final Widget child;
  final bool useSafeArea;
  final bool isDismissible;
  final bool isCentered;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;

  static final ImageFilter _blur = ImageFilter.blur(sigmaX: 12, sigmaY: 12);

  BorderRadiusGeometry? get _resolvedRadius {
    if (isCentered) return null;
    if (borderRadius != null) return borderRadius;
    if (margin != null) return BorderRadius.circular(28);
    return const BorderRadius.vertical(top: Radius.circular(24));
  }

  @override
  Widget build(BuildContext context) {
    final routeAnimation = ModalRoute.of(context)?.animation;
    final hasMargin = margin != null;

    final sheet = Material(
      color: isCentered ? Colors.transparent : AppColors.white,
      elevation: isCentered ? 0 : 8,
      shadowColor: isCentered ? Colors.transparent : Colors.black26,
      borderRadius: _resolvedRadius,
      clipBehavior: isCentered ? Clip.none : Clip.antiAlias,
      child: child,
    );

    final Widget sheetSlot;
    if (isCentered) {
      sheetSlot = useSafeArea ? SafeArea(child: sheet) : sheet;
    } else {
      sheetSlot = useSafeArea ? SafeArea(top: false, child: sheet) : sheet;
    }

    Widget alignedSheet = isCentered
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: sheetSlot,
          )
        : hasMargin
        ? Padding(padding: margin!, child: sheetSlot)
        : sheetSlot;

    if (routeAnimation != null && isCentered) {
      alignedSheet = FadeTransition(
        opacity: CurvedAnimation(parent: routeAnimation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: routeAnimation, curve: Curves.easeOutCubic),
          ),
          child: alignedSheet,
        ),
      );
    }

    final scrim = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDismissible ? () => Navigator.maybePop(context) : null,
      child: BackdropFilter(
        filter: _blur,
        child: ColoredBox(
          color: const Color(0xff044423).withValues(alpha: 0.12),
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: routeAnimation == null
              ? scrim
              : FadeTransition(opacity: routeAnimation, child: scrim),
        ),
        Align(
          alignment: isCentered ? Alignment.center : Alignment.bottomCenter,
          child: alignedSheet,
        ),
      ],
    );
  }
}
