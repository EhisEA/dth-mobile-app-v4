import "dart:ui" show ImageFilter;

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";

class PostMedia extends StatelessWidget {
  const PostMedia({super.key, required this.post, this.onPlayVideo});

  final Post post;

  /// When non-null, tapping a video thumbnail invokes this. Use it on screens
  /// that play videos inline (post detail). Leave null on cards — the parent's
  /// outer tap (navigation) will pass through.
  final VoidCallback? onPlayVideo;

  static const double _mediaHeight = 160;
  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    if (post.isVideo && post.video != null) {
      return _VideoBlock(
        thumbnailUrl: post.video!.thumbnailUrl,
        height: _mediaHeight,
        radius: _radius,
        onPlay: onPlayVideo,
      );
    }
    final urls = post.imageUrls;
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }
    return _ImageGalleryBlock(
      urls: urls,
      height: _mediaHeight,
      radius: _radius,
    );
  }
}

class _VideoBlock extends StatelessWidget {
  const _VideoBlock({
    required this.thumbnailUrl,
    required this.height,
    required this.radius,
    this.onPlay,
  });

  final String thumbnailUrl;
  final double height;
  final double radius;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: onPlay,
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                thumbnailUrl.trim().isEmpty
                    ? const ColoredBox(color: Colors.black)
                    : CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            ColoredBox(color: AppColors.baseShimmer(context)),
                      ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xff121212).withValues(alpha: 0.0),
                        Color(0xff121212).withValues(alpha: 0.80),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Center(
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        color: Colors.black.withValues(alpha: 0.40),
                        child: SvgPicture.asset(
                          SvgAssets.play,
                          height: 24,
                          width: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageGalleryBlock extends StatelessWidget {
  const _ImageGalleryBlock({
    required this.urls,
    required this.height,
    required this.radius,
  });

  final List<String> urls;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final n = urls.length;
    if (n == 1) {
      return _one(urls.first, context);
    }
    if (n == 2) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: _cell(urls[0], context),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: _cell(urls[1], context),
              ),
            ),
          ],
        ),
      );
    }

    final extra = n - 3;
    final r = Radius.circular(radius);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.all(r),
              child: _cell(urls[0], context),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(r),
                    child: _cell(urls[1], context),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(r),
                    child: extra > 0
                        ? _cellWithOverlay(urls[2], context, '$extra+')
                        : _cell(urls[2], context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _one(String url, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: _cell(url, context),
      ),
    );
  }

  Widget _cell(String url, BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          ColoredBox(color: AppColors.baseShimmer(context)),
      errorWidget: (context, url, error) => ColoredBox(
        color: AppColors.baseShimmer(context),
        child: Icon(Icons.broken_image_outlined, color: AppColors.tint15),
      ),
    );
  }

  Widget _cellWithOverlay(
    String url,
    BuildContext context,
    String overlayText,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _cell(url, context),
        ColoredBox(
          color: const Color(0x99000000),
          child: Center(
            child: Text(
              overlayText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
