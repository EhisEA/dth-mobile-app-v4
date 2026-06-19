import 'dart:async';

import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/data.dart';
import 'package:dth_v4/features/app_web_view/app_web_view.dart';
import 'package:dth_v4/features/application/views/application_view.dart';
import 'package:dth_v4/features/application_dashboard/applicant_dashboard.dart';
import 'package:dth_v4/features/bottomNavBar/bottom_nav_bar.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_utils/flutter_utils.dart';

Future<void> handleBannerTap(BannerModel banner, WidgetRef ref) async {
  final navigation = banner.navigation;
  if (navigation == null || !navigation.isTappable) return;

  switch (navigation.type) {
    case BannerNavigationType.none:
      return;
    case BannerNavigationType.inAppNavigation:
      await _handleInAppNavigation(navigation, ref);
    case BannerNavigationType.externalBrowser:
      await _handleExternalBrowser(navigation);
  }
}

Future<void> _handleInAppNavigation(
  BannerNavigationModel navigation,
  WidgetRef ref,
) async {
  // arguments reserved for future deep-link style routing (event uid, etc.).
  switch (navigation.screen) {
    case BannerNavigationScreen.application:
      await MobileNavigationService.instance.navigateTo(ApplicationView.path);
    case BannerNavigationScreen.applicantDashboard:
      await MobileNavigationService.instance.navigateTo(
        ApplicantDashboardView.path,
      );
    case BannerNavigationScreen.subscription:
      _switchBottomNavTab('subscription');
    case BannerNavigationScreen.ticket:
      _switchBottomNavTab('ticket');
    case BannerNavigationScreen.unknown:
      return;
  }
}

void _switchBottomNavTab(String moduleName) {
  final state = BottomNavBar.bottomNavBarKey.currentState;
  if (state == null) {
    DthFlushBar.instance.showGeneric(
      title: 'Unavailable',
      message: 'This section is not available right now.',
    );
    return;
  }
  state.changeTabByModuleName(moduleName);
}

Future<void> _handleExternalBrowser(BannerNavigationModel navigation) async {
  final url = navigation.url?.trim() ?? '';
  if (url.isEmpty) return;

  final uri = Uri.tryParse(url);
  if (uri == null) {
    DthFlushBar.instance.showGeneric(
      title: 'Link',
      message: 'Could not open this link.',
    );
    return;
  }

  final title = uri.host.isNotEmpty ? uri.host : 'Link';
  await MobileNavigationService.instance.navigateTo(
    AppWebView.path,
    extra: {
      RoutingArgumentKey.title: title,
      RoutingArgumentKey.initialURl: url,
    },
  );
}
