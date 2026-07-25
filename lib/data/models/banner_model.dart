enum BannerNavigationType {
  none,
  inAppNavigation,
  externalBrowser;

  static BannerNavigationType fromApi(String? raw) {
    switch (raw?.trim()) {
      case 'in-app-navigation':
        return BannerNavigationType.inAppNavigation;
      case 'external-browser':
        return BannerNavigationType.externalBrowser;
      case 'none':
      default:
        return BannerNavigationType.none;
    }
  }
}

enum BannerNavigationScreen {
  application,
  subscription,
  ticket,
  voting,
  applicantDashboard,
  unknown;

  static BannerNavigationScreen fromApi(String? raw) {
    switch (raw?.trim()) {
      case 'application':
        return BannerNavigationScreen.application;
      case 'subscription':
        return BannerNavigationScreen.subscription;
      case 'ticket':
        return BannerNavigationScreen.ticket;
      case 'voting':
      case 'vote':
        return BannerNavigationScreen.voting;
      case 'applicant-dashboard':
        return BannerNavigationScreen.applicantDashboard;
      default:
        return BannerNavigationScreen.unknown;
    }
  }
}

class BannerNavigationModel {
  const BannerNavigationModel({
    required this.shouldNavigate,
    required this.type,
    required this.screen,
    this.url,
    this.arguments,
  });

  final bool shouldNavigate;
  final BannerNavigationType type;
  final BannerNavigationScreen screen;
  final String? url;
  final Map<String, dynamic>? arguments;

  bool get isTappable => shouldNavigate && type != BannerNavigationType.none;

  factory BannerNavigationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const BannerNavigationModel(
        shouldNavigate: false,
        type: BannerNavigationType.none,
        screen: BannerNavigationScreen.unknown,
      );
    }
    final rawArgs = json['arguments'];
    Map<String, dynamic>? arguments;
    if (rawArgs is Map) {
      arguments = Map<String, dynamic>.from(rawArgs);
    }
    final rawUrl = json['url']?.toString().trim();
    return BannerNavigationModel(
      shouldNavigate: json['should_navigate'] == true,
      type: BannerNavigationType.fromApi(json['type']?.toString()),
      screen: BannerNavigationScreen.fromApi(json['screen']?.toString()),
      url: rawUrl != null && rawUrl.isNotEmpty ? rawUrl : null,
      arguments: arguments,
    );
  }
}

class BannerModel {
  const BannerModel({
    required this.uid,
    required this.imageUrl,
    this.navigation,
  });

  final String uid;
  final String imageUrl;
  final BannerNavigationModel? navigation;

  bool get isTappable => navigation?.isTappable ?? false;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final rawNavigation = json['navigation'];
    BannerNavigationModel? navigation;
    if (rawNavigation is Map) {
      navigation = BannerNavigationModel.fromJson(
        Map<String, dynamic>.from(rawNavigation),
      );
    }
    return BannerModel(
      uid: json['uid']?.toString() ?? '',
      imageUrl: json['url']?.toString() ?? '',
      navigation: navigation,
    );
  }
}
