import "dart:ui" show ImageFilter;

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/components/post_hero.dart";
import "package:dth_v4/features/posts/models/post.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";

class PostMedia extends StatelessWidget {
  const PostMedia({
    super.key,
    required this.post,
    this.onPlayVideo,
    this.enableHero = false,
    this.height,
  });

  final Post post;

  /// When non-null, tapping a video thumbnail invokes this. Use it on screens
  /// that play videos inline (post detail). Leave null on cards — the parent's
  /// outer tap (navigation) will pass through.
  final VoidCallback? onPlayVideo;

  /// Enables the shared [Hero] that flies this media into the post detail
  /// screen. Only the feed [PostCard] sets this — keeping it off elsewhere
  /// (detail fallback media, livestream) avoids two heroes sharing a tag across
  /// simultaneously-alive tabs, which Flutter asserts on.
  final bool enableHero;

  /// Overrides the default feed media height (160). Pinned cards use 194.
  final double? height;

  static const double _mediaHeight = 160;
  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final heroPrefix = enableHero ? post.uid : null;
    return _buildMedia(height: height ?? _mediaHeight, heroPrefix: heroPrefix);
  }

  Widget _buildMedia({required double height, required String? heroPrefix}) {
    if (post.isVideo && post.video != null) {
      return _VideoBlock(
        thumbnailUrl: post.video!.thumbnailUrl,
        height: height,
        radius: _radius,
        onPlay: onPlayVideo,
        heroTag: heroPrefix == null ? null : postVideoHeroTag(heroPrefix),
      );
    }
    final urls = post.imageUrls;
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }
    return _ImageGalleryBlock(
      urls: urls,
      height: height,
      radius: _radius,
      heroPrefix: heroPrefix,
    );
  }
}

class _VideoBlock extends StatelessWidget {
  const _VideoBlock({
    required this.thumbnailUrl,
    required this.height,
    required this.radius,
    this.onPlay,
    this.heroTag,
  });

  final String thumbnailUrl;
  final double height;
  final double radius;
  final VoidCallback? onPlay;

  /// When set, the block flies to the detail screen's pinned player via a
  /// [PostVideoHero]. Null disables the hero (e.g. when rendered somewhere the
  /// transition does not apply).
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final block = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: onPlay,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(thumbnailUrl, fit: BoxFit.cover),
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
    final tag = heroTag;
    if (tag == null) return block;
    return PostVideoHero(tag: tag, thumbnailUrl: thumbnailUrl, child: block);
  }
}

class _ImageGalleryBlock extends StatelessWidget {
  const _ImageGalleryBlock({
    required this.urls,
    required this.height,
    required this.radius,
    required this.heroPrefix,
  });

  final List<String> urls;
  final double height;
  final double radius;

  /// Per-post namespace for the image [Hero] tags (the post uid). Null
  /// disables the hero (primary cell rendered without one).
  final String? heroPrefix;

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
                child: _heroCell(urls[0], context),
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
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.all(r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _heroCell(urls[0], context)),
            const SizedBox(width: 2),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _cell(urls[1], context)),
                  const SizedBox(height: 2),
                  Expanded(
                    child: extra > 0
                        ? _cellWithOverlay(urls[2], context, '$extra+')
                        : _cell(urls[2], context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _one(String url, BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _heroCell(url, context),
      ),
    );
  }

  /// The primary cell, wrapped so it flies to the detail hero / fullscreen
  /// viewer. Only the first image in a gallery gets a hero — the secondary
  /// cells have no counterpart on the detail screen.
  Widget _heroCell(String url, BuildContext context) {
    final prefix = heroPrefix;
    if (prefix == null) return _cell(url, context);
    return PostImageHero(
      tag: postImageHeroTag(prefix, url),
      url: url,
      child: _cell(url, context),
    );
  }

  Widget _cell(String url, BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => const ShimmerBox(),
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
