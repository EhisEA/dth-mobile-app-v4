import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/authentication/views/get_started_view.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Presents a confirmation bottom sheet; on confirm, revokes the session via
/// [UserProfileState.signOut] and clears the navigation stack to [GetStartedView].
Future<void> showLogoutConfirmationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // Present at the root so the sheet sits above the app's bottom
    // navigation bar (the profile screen lives inside a nested Navigator;
    // without this the sheet is z-ordered under the bottom nav and the
    // action buttons get clipped on shorter devices).
    useRootNavigator: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => const _LogoutConfirmationBody(),
  );
}

class _LogoutConfirmationBody extends ConsumerStatefulWidget {
  const _LogoutConfirmationBody();

  @override
  ConsumerState<_LogoutConfirmationBody> createState() =>
      _LogoutConfirmationBodyState();
}

class _LogoutConfirmationBodyState
    extends ConsumerState<_LogoutConfirmationBody> {
  bool _busy = false;

  Future<void> _onConfirm() async {
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      await ref.read(userStateProvider).signOut();
      if (!mounted) return;
      Navigator.of(context).pop();
      MobileNavigationService.instance.navigateAndClearStack(
        GetStartedView.path,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // SafeArea already pads the system bottom inset; the previous code added
    // `MediaQuery.paddingOf(context).bottom` on top of that, which stacked an
    // extra ~34px (iPhone home indicator) / nav-bar height (Android) of dead
    // space below the buttons.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText.semiBold("Log out?", fontSize: 18, color: AppColors.black),
            Gap.h10,
            AppText.regular(
              "You are about to sign out of your account. You will need to log in again to continue.",
              fontSize: 14,
              color: AppColors.blackTint20,
              height: 1.35,
            ),
            Gap.h24,
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    height: 48,
                    radius: 12,
                    fontSize: 15,
                    text: "No",
                    enabled: !_busy,
                    press: () => Navigator.of(context).pop(),
                  ),
                ),
                Gap.w12,
                Expanded(
                  child: AppButton.primary(
                    height: 48,
                    radius: 12,
                    fontSize: 15,
                    text: "Yes",
                    isLoading: _busy,
                    enabled: !_busy,
                    press: _onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
