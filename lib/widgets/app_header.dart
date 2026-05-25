import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/state/app_modules_state.dart';
import 'package:dth_v4/features/notifications/notifications.dart';
import 'package:dth_v4/features/search/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key, required this.onLiveTap});
  final VoidCallback onLiveTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appModules = ref.watch(appModulesStateProvider);
    final navigationService = MobileNavigationService.instance;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(ImageAssets.logo2, height: 32, width: 110),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                navigationService.navigateTo(SearchView.path);
              },
              behavior: HitTestBehavior.opaque,
              child: SvgPicture.asset(SvgAssets.search),
            ),
            Gap.w18,
            if (appModules.appModules.value?.livestream == true) ...[
              GestureDetector(
                onTap: () {
                  onLiveTap();
                  HapticFeedback.lightImpact();
                },
                behavior: HitTestBehavior.opaque,
                child: SvgPicture.asset(SvgAssets.live),
              ),
              Gap.w18,
            ],
            GestureDetector(
              onTap: () {
                navigationService.navigateTo(NotificationsView.path);
                HapticFeedback.lightImpact();
              },
              child: SvgPicture.asset(SvgAssets.notification),
            ),
          ],
        ),
      ],
    );
  }
}
