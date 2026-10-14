import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class StorePromoBanner extends StatelessWidget {
  const StorePromoBanner({super.key, this.onVisitLiveStores});

  final VoidCallback? onVisitLiveStores;

  static const _aspectRatio = 1444 / 621;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Image.asset(
          ImageAssets.storePromo,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );

    if (onVisitLiveStores == null) return image;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onVisitLiveStores!();
      },
      child: image,
    );
  }
}
