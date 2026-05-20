import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/posts/views/photo_viewer.dart";
import "package:flutter/material.dart";

class PostHeroImage extends StatefulWidget {
  const PostHeroImage({
    super.key,
    required this.urls,
    this.aspectRatio = 4 / 5,
  });

  final List<String> urls;
  final double aspectRatio;

  @override
  State<PostHeroImage> createState() => _PostHeroImageState();
}

class _PostHeroImageState extends State<PostHeroImage> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.isEmpty) return const SizedBox.shrink();
    final n = urls.length;
    final isCarousel = n > 1;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: n,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FullscreenImageViewer.open(
                    context,
                    urls: urls,
                    initialIndex: i,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: urls[i],
                    fit: BoxFit.cover,
                    placeholder: (context, _) =>
                        ColoredBox(color: AppColors.baseShimmer(context)),
                    errorWidget: (context, _, _) => ColoredBox(
                      color: AppColors.baseShimmer(context),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.tint15,
                      ),
                    ),
                  ),
                ),
              ),
              // Top gradient so status-bar text / back button stay readable
              // over bright images.
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xff121212).withValues(alpha: 0.45),
                          const Color(0xff121212).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              // if (isCarousel && _current > 0)
              //   Positioned(
              //     left: 8,
              //     top: 0,
              //     bottom: 0,
              //     child: Center(
              //       child: _ChevronButton(
              //         icon: Icons.chevron_left_rounded,
              //         onTap: () => _step(-1),
              //       ),
              //     ),
              //   ),
              // if (isCarousel && _current < n - 1)
              //   Positioned(
              //     right: 8,
              //     top: 0,
              //     bottom: 0,
              //     child: Center(
              //       child: _ChevronButton(
              //         icon: Icons.chevron_right_rounded,
              //         onTap: () => _step(1),
              //       ),
              //     ),
              //   ),
              // if (isCarousel)
              //   Positioned(
              //     top: 0,
              //     right: 12,
              //     child: SafeArea(
              //       bottom: false,
              //       child: _CountBadge(current: _current + 1, total: n),
              //     ),
              //   ),
              if (isCarousel)
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 10,
                  child: Column(
                    children: [
                      // Gap.h12,
                      _PageDots(count: n, current: _current),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: i == current ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i == current ? AppColors.primary : Color(0xFFFCFCFC),
              borderRadius: BorderRadius.circular(3),
              // Drop shadow keeps white inactive dots visible against
              // light-coloured images.
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff121212).withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
