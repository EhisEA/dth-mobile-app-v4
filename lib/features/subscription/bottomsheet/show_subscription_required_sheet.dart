import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/bottomNavBar/bottom_nav_bar.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showSubscriptionRequiredSheet(BuildContext context) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isCentered: true,
    enableDrag: false,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (sheetContext) => const _SubscriptionRequiredSheetBody(),
  );
}

void _openSubscriptionTab() {
  final state = BottomNavBar.bottomNavBarKey.currentState;
  if (state == null) {
    DthFlushBar.instance.showGeneric(
      title: "Unavailable",
      message: "This section is not available right now.",
    );
    return;
  }
  state.changeTabByModuleName("subscription");
}

class _SubscriptionRequiredSheetBody extends StatelessWidget {
  const _SubscriptionRequiredSheetBody();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(ImageAssets.subscribeError),
                Gap.h32,
                AppText.medium(
                  "Subscribe to Access Live Shows",
                  fontSize: 18,
                  color: AppColors.black,
                  textAlign: TextAlign.center,
                ),
                Gap.h16,
                AppText.regular(
                  "Live streams are available to subscribers. Subscribe to watch the show live.",
                  fontSize: 14,
                  height: 1.4,
                  letterSpacing: -0.1,
                  color: const Color(0xff454545),
                  textAlign: TextAlign.center,
                  multiText: true,
                ),
                Gap.h24,
                AppButton.primary(
                  text: "Subscribe now",
                  press: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    _openSubscriptionTab();
                  },
                ),
              ],
            ),
          ),
          Gap.h16,
          Material(
            color: AppColors.white,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).maybePop();
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: const Color(0xff505050),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
