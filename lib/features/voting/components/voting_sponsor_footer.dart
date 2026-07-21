import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/home/home.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Sponsor strip for a sponsorships API section (e.g. `voting`, `poll`).
class VotingSponsorFooter extends ConsumerWidget {
  const VotingSponsorFooter({
    super.key,
    this.sectionName = "voting",
    this.includeSafeAreaPadding = true,
    this.horizontalPadding = 16,
    this.topPadding = 0,
    this.bottomPadding = 14,
    this.backgroundColor,
  });

  /// Key under `SponsorshipsData.sections` (e.g. `voting`, `poll`).
  final String sectionName;

  /// Adds device bottom inset — use for bottom sheets, not in-feed cards.
  final bool includeSafeAreaPadding;

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final Color? backgroundColor;

  static const _fallbackPrefix = "PROUDLY BROUGHT TO YOU BY";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref
        .watch(sponsorshipsViewModelProvider)
        .data
        .section(sectionName);
    if (section == null || !section.hasSponsors) {
      return const SizedBox.shrink();
    }

    final logos = section.sponsors.where((s) => s.hasLogo).toList();
    if (logos.isEmpty) return const SizedBox.shrink();

    final prefix = section.prefix.trim().isEmpty
        ? _fallbackPrefix
        : section.prefix.trim().toUpperCase();
    final safeBottom = includeSafeAreaPadding
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;

    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor ?? AppColors.white),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          bottomPadding + safeBottom,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            AppText.bold(
              prefix,
              fontSize: 10,
              color: AppColors.mainBlack,
              letterSpacing: -0.25,
            ),
            for (final sponsor in logos)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openSponsor(sponsor),
                child: CachedNetworkImage(
                  imageUrl: sponsor.logo,
                  width: _logoWidth(sponsor),
                  height: _logoHeight(sponsor),
                  fit: BoxFit.contain,
                  placeholder: (_, __) => SizedBox(
                    width: _logoWidth(sponsor) ?? 48,
                    height: _logoHeight(sponsor),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double? _logoWidth(SponsorshipSponsor sponsor) => sponsor.width;

  double _logoHeight(SponsorshipSponsor sponsor) {
    if (sponsor.height != null) return sponsor.height!;
    final key = "${sponsor.name} ${sponsor.label}".toLowerCase();
    if (key.contains("malta") || key.contains("guinness")) return 44;
    return 32;
  }

  void _openSponsor(SponsorshipSponsor sponsor) {
    final url = sponsor.url.trim();
    if (url.isEmpty) return;
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
}
