import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/home/banner_navigation.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class HomeBannersBar extends ConsumerStatefulWidget {
  const HomeBannersBar({super.key, required this.banners});

  final List<BannerModel> banners;

  static const double height = 108;
  static const double borderRadius = 14;

  @override
  ConsumerState<HomeBannersBar> createState() => _HomeBannersBarState();
}

class _HomeBannersBarState extends ConsumerState<HomeBannersBar> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  static const _autoPlayInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(HomeBannersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.banners.length <= 1) return;
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) => _advancePage());
  }

  void _advancePage() {
    if (!mounted || !_pageController.hasClients || widget.banners.length <= 1) {
      return;
    }
    final next = (_currentPage + 1) % widget.banners.length;
    unawaited(
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _startAutoPlay();
  }

  void _onBannerTap(BannerModel banner) {
    if (!banner.isTappable) return;
    HapticFeedback.lightImpact();
    unawaited(handleBannerTap(banner, ref));
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;

    return ClipRRect(
      borderRadius: BorderRadius.circular(HomeBannersBar.borderRadius),
      child: SizedBox(
        height: HomeBannersBar.height,
        width: double.infinity,
        child: PageView.builder(
          controller: _pageController,
          itemCount: banners.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final banner = banners[index];
            final image = CachedNetworkImage(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: HomeBannersBar.height,
              placeholder: (_, _) => const ShimmerBox(),
              errorWidget: (_, _, _) =>
                  ColoredBox(color: AppColors.baseShimmer(context)),
            );
            if (!banner.isTappable) return image;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onBannerTap(banner),
              child: image,
            );
          },
        ),
      ),
    );
  }
}
