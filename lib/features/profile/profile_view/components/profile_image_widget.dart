import 'package:cached_network_image/cached_network_image.dart';
import 'package:dth_v4/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProfileImageWidget extends StatelessWidget {
  const ProfileImageWidget({
    super.key,
    this.showEdit = false,
    this.size = 80,
    this.color,
    this.avatar,
    this.onEditTap,
  });

  final bool showEdit;
  final double size;
  final Color? color;
  final String? avatar;
  final VoidCallback? onEditTap;

  /// Badge is ~42% of avatar so it reads as a corner seal, not a full-width strip.
  double get _badgeSize => size * 0.42;

  static bool _hasUsableAvatarUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    final useNetwork = _hasUsableAvatarUrl(avatar);
    final tint = color ?? const Color(0xffECECEC);
    final badgeSize = _badgeSize;
    // Pull the seal onto the top-right corner so roughly half overlaps the frame.
    final badgeInset = badgeSize * 0.28;

    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xffFDCA03),
                      Color(0xffFBFA69),
                      Color(0xffBC3B03),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: useNetwork
                      ? CachedNetworkImage(
                          imageUrl: avatar!.trim(),
                          fit: BoxFit.cover,
                          width: size,
                          height: size,
                          placeholder: (context, url) =>
                              _placeholderImage(size: size, tint: tint),
                          errorWidget: (context, url, error) =>
                              _placeholderImage(size: size, tint: tint),
                        )
                      : Center(
                          child: _placeholderImage(size: size, tint: tint),
                        ),
                ),
              ),
            ),
            Positioned(
              top: -badgeInset,
              right: -badgeInset,
              width: badgeSize,
              height: badgeSize,
              child: Image.asset(
                ImageAssets.userNew,
                width: badgeSize,
                height: badgeSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            if (showEdit)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onEditTap,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          SvgAssets.profileEdit,
                          height: 14,
                          width: 14,
                          colorFilter: ColorFilter.mode(
                            AppColors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _placeholderImage({required double size, required Color tint}) {
    return Image.asset(
      ImageAssets.user,
      height: size,
      width: size,
      color: tint,
      colorBlendMode: BlendMode.darken,
    );
  }
}
