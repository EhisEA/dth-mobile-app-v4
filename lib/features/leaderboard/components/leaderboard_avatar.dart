import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";

class LeaderboardAvatar extends StatelessWidget {
  const LeaderboardAvatar({
    super.key,
    required this.avatarUrl,
    required this.frameAsset,
    this.size = 51,
  });

  final String? avatarUrl;
  final String frameAsset;
  final double size;

  /// Photo fills the scallop hole and tucks under the gold ring (~90%).
  /// Frame PNG hole is ~84–86% of outer size; sizing above that removes the
  /// background gap so the gradient border sits on top of the image.
  double get _photoSize => size * 0.90;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? "";
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: _photoSize,
            height: _photoSize,
            child: ClipOval(
              child: url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: _photoSize,
                      height: _photoSize,
                      placeholder: (_, _) => _placeholder(),
                      errorWidget: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Image.asset(
            frameAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      ImageAssets.user,
      fit: BoxFit.cover,
      width: _photoSize,
      height: _photoSize,
    );
  }
}
