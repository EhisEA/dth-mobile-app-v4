import "dart:ui";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/application/view_model/application_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";


class ApplicationLandingView extends ConsumerWidget {
  const ApplicationLandingView({super.key});

  static const String path = NavigatorRoutes.applicationLanding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(applicationViewModelProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(ImageAssets.applicationBg),
              fit: BoxFit.contain,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18, top: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: AppText.regular(
                              "Dismiss",
                              fontSize: 12,
                              color: Color(0xffFCFCFC),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: AppButton.primary(
                    text: "Apply Now",
                    isLoading: vm.isBaseBusy,
                    press: () {
                      // vm.fetchApplicationProcess(
                      //   onSuccess: () {
                      //     MobileNavigationService.instance.navigateTo(
                      //       ApplicationView.path,
                      //     );
                      //   },
                      // );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
