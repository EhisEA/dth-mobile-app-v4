import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:dth_v4/features/application/view_model/sponsor_view_model.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SponsorFooter extends ConsumerStatefulWidget {
  const SponsorFooter({super.key});

  @override
  ConsumerState<SponsorFooter> createState() => _SponsorFooterState();
}

class _SponsorFooterState extends ConsumerState<SponsorFooter> {
  // Owned once and disposed with the State — building a new recognizer inside
  // build() on every provider notify would orphan (leak) the previous ones.
  final TapGestureRecognizer _tapRecognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(sponsorViewModelProvider).load());
    });
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sponsor = ref.watch(sponsorViewModelProvider).sponsor;
    if (sponsor == null || !sponsor.isDisplayable) {
      return const SizedBox.shrink();
    }

    final prefix = sponsor.prefix.trim();
    final label = sponsor.label.trim();
    final link = sponsor.link.trim();

    _tapRecognizer.onTap = link.isEmpty
        ? null
        : () {
            unawaited(
              MobileNavigationService.instance.navigateTo(
                AppWebView.path,
                extra: {
                  RoutingArgumentKey.title: label,
                  RoutingArgumentKey.initialURl: link,
                },
              ),
            );
          };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Text.rich(
        TextSpan(
          style: AppTextStyle.regular.copyWith(
            fontSize: 12,
            color: AppColors.blackTint20,
          ),
          children: [
            if (prefix.isNotEmpty)
              TextSpan(
                text: prefix.endsWith(" ") ? prefix : "$prefix ",
                style: AppTextStyle.regular.copyWith(
                  fontSize: 12,
                  color: AppColors.blackTint20,
                ),
              ),
            TextSpan(
              text: label,
              style: AppTextStyle.regular.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sponsor.accentColor,
              ),
              recognizer: link.isNotEmpty ? _tapRecognizer : null,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
