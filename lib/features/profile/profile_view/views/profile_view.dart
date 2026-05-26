import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/data.dart';
import 'package:dth_v4/features/app_web_view/app_web_view.dart';
import 'package:dth_v4/features/application/views/application_view.dart';
import 'package:dth_v4/features/application_dashboard/applicant_dashboard.dart';
import 'package:dth_v4/features/profile/logout/logout.dart';
import 'package:dth_v4/features/profile/profile.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_utils/flutter_utils.dart';

final profileViewModel = ChangeNotifierProvider(
  (ref) => ProfileViewModel(ref.read(userProfileStateProvider)),
);

String _profileBackgroundForRole(ParticipationRole role) {
  switch (role) {
    case ParticipationRole.contestant:
      return ImageAssets.contestantBg;
    case ParticipationRole.applicant:
      return ImageAssets.applicantBg;
    case ParticipationRole.user:
    case ParticipationRole.unknown:
      return ImageAssets.userBg;
  }
}

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});
  static const String path = NavigatorRoutes.profile;

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final MobileNavigationService _navigationService =
      MobileNavigationService.instance;
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userStateProvider);
    return ValueListenableBuilder<UserModel?>(
      valueListenable: userState.user,
      builder: (context, user, _) {
        final appModules = ref.watch(appModulesStateProvider);
        final modulesPayload = appModules.appModules.value;
        final hideApplicantDashboardTile =
            user?.participationRole == ParticipationRole.user &&
            modulesPayload?.application == false;
        final showApplicantDashboardTile =
            (user?.eligible ?? false) && !hideApplicantDashboardTile;
        final role = user?.participationRole ?? ParticipationRole.user;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(_profileBackgroundForRole(role)),
              alignment: Alignment.topCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Gap.h30,
                      Center(
                        child: ProfileImageWidget(
                          size: 64,
                          color: AppColors.white,
                          avatar: user?.avatar,
                        ),
                      ),
                      Gap.h16,
                      AppText.semiBold(
                        user?.fullName ?? "",
                        centered: true,
                        fontSize: 18,
                        color: AppColors.mainBlack,
                      ),
                      Gap.h2,
                      AppText.regular(
                        user?.email ?? "",
                        centered: true,
                        fontSize: 12,
                        color: AppColors.tint15,
                      ),
                      ContestantPill(user: user),
                      if (user?.participationRole == ParticipationRole.user &&
                          appModules.appModules.value?.application == true) ...[
                        Gap.h32,
                        ApplicationWidget(
                          participationRole:
                              user?.participationRole ?? ParticipationRole.user,
                          onTap: () {
                            _navigationService.navigateTo(ApplicationView.path);
                          },
                        ),
                        Gap.h32,
                      ],
                      AppText.medium(
                        "Account Settings",
                        fontSize: 12,
                        color: AppColors.tint15,
                      ),
                      Gap.h24,
                      if (!showApplicantDashboardTile)
                        const SizedBox.shrink()
                      else ...[
                        ContestantDashboardTile(
                          role: role,
                          applicationStatus: user?.applicationStatus,
                          onTap: () {
                            _navigationService.navigateTo(
                              ApplicantDashboardView.path,
                            );
                          },
                        ),
                        Gap.h32,
                      ],
                      ProfileTlle(
                        title: "Personal Information",
                        description: "Update your profile information",
                        icon: SvgAssets.personal,
                        showRightArrow: false,
                        onTap: () {
                          if (user == null) return;
                          _navigationService.navigateTo(
                            PersonalInfomationView.path,
                          );
                        },
                      ),

                      Gap.h32,
                      AppText.medium(
                        "Support & Legal",
                        fontSize: 12,
                        color: AppColors.tint15,
                      ),
                      Gap.h24,
                      ProfileTlle(
                        title: "Terms & Conditions",
                        description:
                            "Review the guidelines for using this platform",
                        icon: SvgAssets.terms,
                        onTap: () {
                          _navigationService.navigateTo(
                            AppWebView.path,
                            extra: {
                              RoutingArgumentKey.title: "Terms & Conditions",
                              RoutingArgumentKey.initialURl:
                                  AppLink.termsAndConditions,
                            },
                          );
                        },
                      ),
                      Gap.h28,
                      ProfileTlle(
                        title: "Privacy Policy",
                        description: "See how your data is handled",
                        icon: SvgAssets.privacy,
                        onTap: () {
                          _navigationService.navigateTo(
                            AppWebView.path,
                            extra: {
                              RoutingArgumentKey.title: "Privacy Policy",
                              RoutingArgumentKey.initialURl:
                                  AppLink.privacyPolicy,
                            },
                          );
                        },
                      ),
                      // Gap.h28,
                      // ProfileTlle(
                      //   title: "Social Media Community",
                      //   description:
                      //       "Connect with our community and stay updated",
                      //   icon: SvgAssets.social,
                      //   onTap: () {},
                      // ),
                      Gap.h28,
                      ProfileTlle(
                        title: "Learn More",
                        description: "Discover more about De9jaTalenthunt",
                        icon: SvgAssets.learn,
                        onTap: () {
                          MobileNavigationService.instance.navigateTo(
                            AppWebView.path,
                            extra: {
                              RoutingArgumentKey.title: "Learn More",
                              RoutingArgumentKey.initialURl: AppLink.dthWebsite,
                            },
                          );
                        },
                      ),
                      Gap.h32,
                      AppText.medium(
                        "Account Actions",
                        fontSize: 12,
                        color: AppColors.tint15,
                      ),
                      Gap.h24,
                      ProfileTlle(
                        title: "Log Out",
                        description: "Sign out of your account",
                        icon: SvgAssets.logout,
                        isRed: true,
                        showRightArrow: false,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          showLogoutConfirmationSheet(context);
                        },
                      ),
                      Gap.h28,
                      ProfileTlle(
                        title: "Delete Account",
                        description: "Delete your account permanently",
                        icon: SvgAssets.delete,
                        isRed: true,
                        onTap: () {
                          ref
                              .read(deleteAccountViewModelProvider)
                              .resetForNewFlow();
                          MobileNavigationService.instance.navigateTo(
                            DeleteAccountConsentView.path,
                          );
                        },
                      ),
                      Gap.h30,
                      Gap.h30,
                      Gap.h30,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
