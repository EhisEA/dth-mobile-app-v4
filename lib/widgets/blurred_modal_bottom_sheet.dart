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
    useSafeArea: false,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    sheetAnimationStyle: sheetAnimationStyle,
    requestFocus: requestFocus,
    builder: (modalContext) => _BlurredBottomSheetFrame(
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      child: builder(modalContext),
    ),
  );
}

class _BlurredBottomSheetFrame extends StatelessWidget {
  const _BlurredBottomSheetFrame({
    required this.child,
    required this.useSafeArea,
    required this.isDismissible,
  });

  final Widget child;
  final bool useSafeArea;
  final bool isDismissible;

  static final ImageFilter _blur = ImageFilter.blur(sigmaX: 12, sigmaY: 12);

  @override
  Widget build(BuildContext context) {
    final sheet = Material(
      color: AppColors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    final sheetSlot = useSafeArea ? SafeArea(top: false, child: sheet) : sheet;

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
        Align(alignment: Alignment.bottomCenter, child: sheetSlot),
      ],
    );
  }
}
