import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/state/app_modules_state.dart';
import 'package:dth_v4/features/leaderboard/leaderboard.dart';
import 'package:dth_v4/features/notifications/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appModules = ref.watch(appModulesStateProvider);
    final hasUnread = ref.watch(
      notificationsViewModelProvider.select((vm) => vm.hasUnread),
    );
    final navigationService = MobileNavigationService.instance;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(ImageAssets.logo2, height: 36, width: 110),
        Row(
          children: [
            if (appModules.appModules.value?.leaderboard == true) ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  navigationService.navigateTo(LeaderboardView.path);
                },
                behavior: HitTestBehavior.opaque,
                child: SvgPicture.asset(SvgAssets.leaderboard, width: 24),
              ),
              Gap.w16,
            ],
            GestureDetector(
              onTap: () {
                navigationService.navigateTo(NotificationsView.path);
                HapticFeedback.lightImpact();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      SvgAssets.notification,
                      height: 24,
                      width: 24,
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 3,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.redTint35,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
