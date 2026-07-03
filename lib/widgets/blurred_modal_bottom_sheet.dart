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
  });

  final Widget child;
  final bool useSafeArea;
  final bool isDismissible;
  final bool isCentered;

  static final ImageFilter _blur = ImageFilter.blur(sigmaX: 12, sigmaY: 12);

  @override
  Widget build(BuildContext context) {
    final sheet = Material(
      color: isCentered ? Colors.transparent : AppColors.white,
      elevation: isCentered ? 0 : 8,
      shadowColor: isCentered ? Colors.transparent : Colors.black26,
      borderRadius: isCentered
          ? null
          : const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: isCentered ? Clip.none : Clip.antiAlias,
      child: child,
    );

    final Widget sheetSlot;
    if (isCentered) {
      sheetSlot = useSafeArea ? SafeArea(child: sheet) : sheet;
    } else {
      sheetSlot = useSafeArea ? SafeArea(top: false, child: sheet) : sheet;
    }

    final alignedSheet = isCentered
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: sheetSlot,
          )
        : sheetSlot;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isDismissible ? () => Navigator.maybePop(context) : null,
            child: BackdropFilter(
              filter: _blur,
              child: ColoredBox(
                color: Color(0xfF044423).withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        Align(
          alignment: isCentered ? Alignment.center : Alignment.bottomCenter,
          child: alignedSheet,
        ),
      ],
    );
  }
}
