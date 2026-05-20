import "package:dth_v4/core/router/router.dart";
import 'package:dth_v4/data/data.dart';
import 'package:dth_v4/features/app_web_view/app_web_view.dart';
import 'package:dth_v4/features/application/views/application_landing_view.dart';
import 'package:dth_v4/features/application/views/application_review_view.dart';
import 'package:dth_v4/features/application/views/application_view.dart';
import 'package:dth_v4/features/application_dashboard/applicant_dashboard.dart';
import 'package:dth_v4/features/authentication/views/create_account_view.dart';
import 'package:dth_v4/features/authentication/views/get_started_view.dart';
import 'package:dth_v4/features/authentication/views/login_view.dart';
import 'package:dth_v4/features/authentication/views/verify_otp_view.dart';
import 'package:dth_v4/features/bottomNavBar/bottom_nav_bar.dart';
import 'package:dth_v4/features/home/views/home_view.dart';
import 'package:dth_v4/features/notifications/notifications.dart';
import 'package:dth_v4/features/posts/views/comment_thread_view.dart';
import 'package:dth_v4/features/posts/views/post_detail_view.dart';
import 'package:dth_v4/features/profile/delete_account/views/delete_account_consent_view.dart';
import 'package:dth_v4/features/profile/delete_account/views/delete_account_otp_view.dart';
import 'package:dth_v4/features/profile/personal_information/views/personal_infomation_view.dart';
import 'package:dth_v4/features/profile/personal_information/views/profile_phone_verify_otp_view.dart';
import 'package:dth_v4/features/stories/views/stories_view.dart';
import 'package:dth_v4/features/search/views/search_view.dart';
import 'package:dth_v4/features/splash/views/splash_view.dart';
import 'package:dth_v4/features/subscription/subscription.dart';
import 'package:dth_v4/features/tickets/tickets.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static PageRoute _getPageRoute({
    required RouteSettings settings,
    required Widget viewToShow,
  }) {
    return MaterialPageRoute(
      builder: (context) => viewToShow,
      settings: settings,
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    Map<String, dynamic> routeArgs = settings.arguments != null
        ? settings.arguments as Map<String, dynamic>
        : {};

    switch (settings.name) {
      case BottomNavBar.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const BottomNavBar(),
        );

      case SplashView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const SplashView(),
        );

      ////////////////AUTHVIEW////////////////////
      case GetStartedView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const GetStartedView(),
        );

      case CreateAccountView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const CreateAccountView(),
        );

      case LoginView.path:
        return _getPageRoute(settings: settings, viewToShow: const LoginView());

      case VerifyOtpView.path:
        final email = routeArgs[RoutingArgumentKey.email] as String? ?? '';
        return _getPageRoute(
          settings: settings,
          viewToShow: VerifyOtpView(
            email: email,
            signature: routeArgs[RoutingArgumentKey.signature] as String?,
            otpFlow: routeArgs[RoutingArgumentKey.otpFlow] as String?,
            ttlSeconds: routeArgs['ttlSeconds'] as int?,
          ),
        );

      ////////////////HOME VIEW////////////////////
      case HomeView.path:
        return _getPageRoute(settings: settings, viewToShow: const HomeView());
      case StoriesView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: StoriesView(
            reelUid: routeArgs[RoutingArgumentKey.reelUid] as String? ?? "",
          ),
        );
      case PostDetailView.path:
        final uid = routeArgs[RoutingArgumentKey.postUid] as String? ?? "";
        return _getPageRoute(
          settings: settings,
          viewToShow: PostDetailView(uid: uid),
        );
      case CommentThreadView.path:
        final commentUid =
            routeArgs[RoutingArgumentKey.commentUid] as String? ?? "";
        return _getPageRoute(
          settings: settings,
          viewToShow: CommentThreadView(commentUid: commentUid),
        );
      ////////////////SEARCH VIEW////////////////////
      case SearchView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const SearchView(),
        );

      ////////////////WEB VIEW////////////////////
      case AppWebView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: AppWebView(
            initialURl:
                routeArgs[RoutingArgumentKey.initialURl] as String? ?? "",
            title: routeArgs[RoutingArgumentKey.title] as String? ?? "",
            callbackUrl:
                routeArgs[RoutingArgumentKey.callbackUrl] as String? ?? "",
            showOpenInExternalBrowser:
                routeArgs[RoutingArgumentKey.showOpenInExternalBrowser]
                    as bool? ??
                true,
          ),
        );
      ////////////////APPLICATION VIEW////////////////////
      case ApplicationLandingView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const ApplicationLandingView(),
        );

      case ApplicationView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const ApplicationView(),
        );

      case ApplicationReviewView.path:
        final reviewDraft =
            routeArgs[RoutingArgumentKey.applicationDraft] as ApplicationDraft?;
        return _getPageRoute(
          settings: settings,
          viewToShow: ApplicationReviewView(routeDraft: reviewDraft),
        );

      ////////////////PROFILE VIEW////////////////////
      case PersonalInfomationView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const PersonalInfomationView(),
        );

      case ProfilePhoneVerifyOtpView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const ProfilePhoneVerifyOtpView(),
        );

      case DeleteAccountConsentView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const DeleteAccountConsentView(),
        );

      case DeleteAccountOtpView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const DeleteAccountOtpView(),
        );

      ////////////////SUBSCRIPTION VIEW////////////////////
      case ConfirmationView.path:
        final confirmationSuccess =
            routeArgs[RoutingArgumentKey.confirmationSuccess] as bool? ?? true;
        final confirmationFlow = ConfirmationFlow.fromRouteValue(
          routeArgs[RoutingArgumentKey.confirmationFlow],
        );
        final confirmationEventUid =
            routeArgs[RoutingArgumentKey.confirmationEventUid] as String?;
        final confirmationOnSuccess =
            routeArgs[RoutingArgumentKey.confirmationOnSuccess]
                as Future<void> Function()?;
        final confirmationSuccessDescription =
            routeArgs[RoutingArgumentKey.confirmationSuccessDescription]
                as String? ??
            "";
        final confirmationFailureDescription =
            routeArgs[RoutingArgumentKey.confirmationFailureDescription]
                as String? ??
            "";
        return _getPageRoute(
          settings: settings,
          viewToShow: ConfirmationView(
            isSuccess: confirmationSuccess,
            successDescription: confirmationSuccessDescription,
            failureDescription: confirmationFailureDescription,
            flow: confirmationFlow,
            eventUid: confirmationEventUid,
            onSuccess: confirmationOnSuccess,
          ),
        );

      ////////////////TICKETS VIEW////////////////////
      case UpcomingShowsView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const UpcomingShowsView(),
        );

      case ShowView.path:
        final eventUid =
            routeArgs[RoutingArgumentKey.eventUid] as String? ?? "";
        return _getPageRoute(
          settings: settings,
          viewToShow: ShowView(eventUid: eventUid),
        );

      case PurchaseTicketsView.path:
        final purchaseEventUid =
            routeArgs[RoutingArgumentKey.eventUid] as String? ?? "";
        final onPurchaseSuccess =
            routeArgs[RoutingArgumentKey.onPurchaseSuccess]
                as Future<void> Function()?;
        return _getPageRoute(
          settings: settings,
          viewToShow: PurchaseTicketsView(
            eventUid: purchaseEventUid,
            onPurchaseSuccess: onPurchaseSuccess,
          ),
        );

      case YourTicketsView.path:
        final ticketsExtra =
            routeArgs[RoutingArgumentKey.yourTicketsArgs]
                as Map<String, dynamic>? ??
            routeArgs;
        final purchasedTicket =
            YourTicketsArgs.fromRouteExtra(ticketsExtra).purchasedTicket;
        return _getPageRoute(
          settings: settings,
          viewToShow: YourTicketsView(purchasedTicket: purchasedTicket),
        );
      ////////////////APPLICANT DASHBOARD VIEW////////////////////
      case ApplicantDashboardView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const ApplicantDashboardView(),
        );

      ////////////////NOTIFICATIONS VIEW////////////////////
      case NotificationsView.path:
        return _getPageRoute(
          settings: settings,
          viewToShow: const NotificationsView(),
        );

      default:
        return _getPageRoute(
          settings: settings,
          viewToShow: Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
