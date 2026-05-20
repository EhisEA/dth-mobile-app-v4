import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    this.activeIcon,
    required this.isActive,
    this.onTap,
    this.semanticLabel,
  });

  final String icon;
  final String? activeIcon;
  final bool isActive;
  final VoidCallback? onTap;

  /// Spoken by screen readers; should match the tab title from the server.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconToUse = isActive ? (activeIcon ?? icon) : icon;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : kMinInteractiveDimension;

        void handleTap() {
          onTap?.call();
          HapticFeedback.lightImpact();
        }

        return Semantics(
          button: true,
          label: semanticLabel,
          child: InkWell(
            onTap: handleTap,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: SizedBox(
              width: w,
              height: h,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  child: SvgPicture.asset(
                    iconToUse,
                    width: isActive ? 24 : 24,
                    height: isActive ? 24 : 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
