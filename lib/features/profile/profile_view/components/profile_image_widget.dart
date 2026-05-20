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
                decoration: BoxDecoration(
                  color: AppColors.baseShimmerLight,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.hardEdge,
                child: useNetwork
                    ? CachedNetworkImage(
                        imageUrl: avatar!.trim(),
                        fit: BoxFit.cover,
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
