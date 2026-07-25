import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/home/home.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Infinite fade carousel of voting sponsor feature images.
class VotingSponsorImageCarousel extends ConsumerStatefulWidget {
  const VotingSponsorImageCarousel({super.key});

  static const double height = 105;
  static const double borderRadius = 12;

  @override
  ConsumerState<VotingSponsorImageCarousel> createState() =>
      _VotingSponsorImageCarouselState();
}

class _VotingSponsorImageCarouselState
    extends ConsumerState<VotingSponsorImageCarousel> {
  Timer? _autoPlayTimer;
  int _currentIndex = 0;
  List<SponsorshipSponsor> _sponsors = const [];
  String? _shuffledKey;

  static const _autoPlayInterval = Duration(seconds: 4);
  static const _fadeDuration = Duration(milliseconds: 650);
  static const _swipeVelocityThreshold = 200.0;

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  String _keyFor(List<SponsorshipSponsor> sponsors) =>
      sponsors.map((s) => s.uid).join("|");

  void _syncSponsors(List<SponsorshipSponsor> source) {
    final key = _keyFor(source);
    if (_shuffledKey == key) return;
    _shuffledKey = key;
    _sponsors = List<SponsorshipSponsor>.of(source)..shuffle();
    _currentIndex = 0;
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_sponsors.length <= 1) return;
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) => _goNext());
  }

  void _goNext() {
    if (!mounted || _sponsors.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _sponsors.length;
    });
  }

  void _goPrevious() {
    if (!mounted || _sponsors.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _sponsors.length) % _sponsors.length;
    });
    _startAutoPlay();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_sponsors.length <= 1) return;
    final vx = details.primaryVelocity ?? 0;
    if (vx <= -_swipeVelocityThreshold) {
      _goNext();
      _startAutoPlay();
    } else if (vx >= _swipeVelocityThreshold) {
      _goPrevious();
    }
  }

  void _openSponsor(SponsorshipSponsor sponsor) {
    final url = sponsor.url.trim();
    if (url.isEmpty) return;
    HapticFeedback.lightImpact();
    unawaited(
      MobileNavigationService.instance.navigateTo(
        AppWebView.path,
        extra: {
          RoutingArgumentKey.title: sponsor.label,
          RoutingArgumentKey.initialURl: url,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = ref.watch(sponsorshipsViewModelProvider).voting;
    final withImages = section == null
        ? const <SponsorshipSponsor>[]
        : section.sponsors.where((s) => s.hasImage).toList(growable: false);

    if (withImages.isEmpty) {
      _autoPlayTimer?.cancel();
      return const SizedBox.shrink();
    }

    _syncSponsors(withImages);
    final sponsor = _sponsors[_currentIndex % _sponsors.length];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gap.h24,
        ClipRRect(
          borderRadius: BorderRadius.circular(
            VotingSponsorImageCarousel.borderRadius,
          ),
          child: SizedBox(
            height: VotingSponsorImageCarousel.height,
            width: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onTap: () => _openSponsor(sponsor),
              child: AnimatedSwitcher(
                duration: _fadeDuration,
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: CachedNetworkImage(
                  key: ValueKey(sponsor.uid),
                  imageUrl: sponsor.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: VotingSponsorImageCarousel.height,
                  placeholder: (_, __) =>
                      ShimmerBox(baseColor: AppColors.baseShimmer(context)),
                  errorWidget: (_, __, ___) =>
                      ColoredBox(color: AppColors.baseShimmer(context)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
