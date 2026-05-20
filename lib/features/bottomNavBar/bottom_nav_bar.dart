import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/bottomNavBar/bottomsheet/show_phone_verification_sheet.dart";
import "package:dth_v4/features/bottomNavBar/components/nav_item.dart";
import "package:dth_v4/features/bottomNavBar/phone_verification_eligibility.dart";
import "package:dth_v4/features/bottomNavBar/viewmodel/bottom_nav_bar_view_model.dart";
import "package:dth_v4/features/home/views/home_view.dart";
import "package:dth_v4/features/profile/profile_view/views/profile_view.dart";
import "package:dth_v4/features/search/views/search_view.dart";
import "package:dth_v4/features/subscription/views/subscription_view.dart";
import "package:dth_v4/features/tickets/tickets.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart";

final bottomNavBarViewModel = ChangeNotifierProvider.autoDispose(
  (ref) => BottomNavBarViewModel(
    ref.read(userStateProvider),
    ref.read(subscriptionPlansStateProvider),
  ),
);

class _NavBinding {
  const _NavBinding({
    required this.label,
    required this.assetInactive,
    required this.assetActive,
    required this.screen,
  });
  final String label;
  final String assetInactive;
  final String assetActive;
  final Widget screen;
}

/// Maps an `AppModuleNavItem.name` (server-controlled identifier) to its
/// concrete tab UI: icons + screen widget. Items the server doesn't include
/// are simply not rendered.
_NavBinding? _bindNavItem(AppModuleNavItem item) {
  switch (item.name) {
    case 'timeline':
      return _NavBinding(
        label: item.label,
        assetInactive: SvgAssets.home,
        assetActive: SvgAssets.homeActive,
        screen: const HomeView(),
      );
    case 'search':
      return _NavBinding(
        label: item.label,
        assetInactive: SvgAssets.search,
        assetActive: SvgAssets.searchActive,
        screen: const SearchView(),
      );
    case 'tickets':
      return _NavBinding(
        label: item.label,
        assetInactive: SvgAssets.ticket,
        assetActive: SvgAssets.ticketActive,
        screen: const TicketView(),
      );
    case 'subscriptions':
      return _NavBinding(
        label: item.label,
        assetInactive: SvgAssets.verify,
        assetActive: SvgAssets.verifyActive,
        screen: const SubscriptionView(),
      );
    case 'profile':
      return _NavBinding(
        label: item.label,
        assetInactive: SvgAssets.profile,
        assetActive: SvgAssets.profileActive,
        screen: const ProfileView(),
      );
    default:
      return null;
  }
}

/// Fallback used when the modules call hasn't returned yet or failed —
/// matches the previous hard-coded layout so users never see a blank nav.
final List<_NavBinding> _kFallbackBindings = [
  _NavBinding(
    label: 'Home',
    assetInactive: SvgAssets.home,
    assetActive: SvgAssets.homeActive,
    screen: const HomeView(),
  ),
  _NavBinding(
    label: 'Search',
    assetInactive: SvgAssets.search,
    assetActive: SvgAssets.searchActive,
    screen: const SearchView(),
  ),
  _NavBinding(
    label: 'Tickets',
    assetInactive: SvgAssets.ticket,
    assetActive: SvgAssets.ticketActive,
    screen: const TicketView(),
  ),
  _NavBinding(
    label: 'Subscription',
    assetInactive: SvgAssets.verify,
    assetActive: SvgAssets.verifyActive,
    screen: const SubscriptionView(),
  ),
  _NavBinding(
    label: 'Profile',
    assetInactive: SvgAssets.profile,
    assetActive: SvgAssets.profileActive,
    screen: const ProfileView(),
  ),
];

class BottomNavBar extends ConsumerStatefulWidget {
  static const String path = NavigatorRoutes.bottomNavBar;
  const BottomNavBar({super.key});

  static GlobalKey<BottomNavBarState> bottomNavBarKey =
      GlobalKey<BottomNavBarState>();

  @override
  ConsumerState<BottomNavBar> createState() => BottomNavBarState();
}

class BottomNavBarState extends ConsumerState<BottomNavBar> {
  /// Resolves the tab list from the server-provided `navigation` payload.
  /// Falls back to the static set if modules haven't loaded yet — splash
  /// awaits the call before navigating here, so this fallback is only a
  /// safety net for retry/failure paths.
  List<_NavBinding> _resolveBindings() {
    final modules = ref.read(appModulesStateProvider).appModules.value;
    final navItems = modules?.navigation ?? const <AppModuleNavItem>[];
    if (navItems.isEmpty) return _kFallbackBindings;
    final bindings = navItems
        .map(_bindNavItem)
        .whereType<_NavBinding>()
        .toList(growable: false);
    return bindings.isEmpty ? _kFallbackBindings : bindings;
  }

  final PersistentTabController _tabController = PersistentTabController(
    initialIndex: 0,
  );
  DateTime? _lastBackPress;
  Timer? _exitTimer;
  static const _exitWindow = Duration(seconds: 2);
  bool _phoneVerificationSheetShown = false;

  void changeTab(int newIndex) {
    final bindings = _resolveBindings();
    if (newIndex < 0 || newIndex >= bindings.length) return;
    _tabController.jumpToTab(newIndex);
  }

  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop) return;
    final onDashboard = _tabController.index == 0;
    if (!onDashboard) {
      _tabController.jumpToTab(0);
      return;
    }
    final now = DateTime.now();
    final isSecondBack =
        _lastBackPress != null && now.difference(_lastBackPress!) < _exitWindow;
    if (isSecondBack) {
      _exitTimer?.cancel();
      _lastBackPress = null;
      unawaited(SystemNavigator.pop());
      return;
    }
    _lastBackPress = now;
    _exitTimer?.cancel();
    _exitTimer = Timer(_exitWindow, () {
      if (mounted) _lastBackPress = null;
    });
    if (mounted) {
      DthFlushBar.instance.showSuccess(
        message: "Press back again to exit",
        title: "Oh!",
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  void _tryShowPhoneVerificationSheet() {
    if (_phoneVerificationSheetShown || !mounted) return;
    final user = ref.read(userStateProvider).user.value;
    if (user == null || !shouldEnforcePhoneVerification(user)) return;
    _phoneVerificationSheetShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(showPhoneVerificationBottomSheet(context, user: user));
    });
  }

  @override
  void initState() {
    super.initState();
    final model = ref.read(bottomNavBarViewModel);
    unawaited(
      Future.microtask(() async {
        await model.userState.getUserDetails();
        if (!mounted) return;
        unawaited(model.subscriptionPlansState.fetchPlans());
        _tryShowPhoneVerificationSheet();
      }),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Widget _buildCustomNavBar(List<_NavBinding> bindings) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPad = bottomInset > 0 ? 4.0 : 8.0;
    return Material(
      color: AppColors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: LayoutBuilder(
        builder: (context, c) {
          final outerH = c.maxHeight.isFinite ? c.maxHeight : 84.0;
          final innerH = (outerH - bottomPad).clamp(1.0, 400.0);
          return Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: SizedBox(
              height: innerH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < bindings.length; i++)
                    Expanded(
                      child: NavItem(
                        icon: bindings[i].assetInactive,
                        activeIcon: bindings[i].assetActive,
                        isActive: _tabController.index == i,
                        semanticLabel: bindings[i].label,
                        onTap: () {
                          setState(() {
                            _tabController.index = i;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(bottomNavBarViewModel);
    // Watch the modules notifier so a late-arriving fetch (retry after a
    // failed splash call) rebuilds the nav with the server's tab list.
    final modulesState = ref.watch(appModulesStateProvider);
    return ValueListenableBuilder<UserModel?>(
      valueListenable: model.userModel,
      builder: (context, userModel, _) {
        return ValueListenableBuilder<AppModulesModel?>(
          valueListenable: modulesState.appModules,
          builder: (context, _, _) {
            final bindings = _resolveBindings();
            // Clamp the active index in case the server returned fewer
            // tabs than the previous render had.
            if (_tabController.index >= bindings.length) {
              _tabController.index = 0;
            }
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: _onPopInvoked,
              child: PersistentTabView.custom(
                context,
                backgroundColor: Colors.transparent,
                controller: _tabController,
                handleAndroidBackButtonPress: false,
                screens: [
                  for (final b in bindings)
                    CustomNavBarScreen(screen: b.screen),
                ],
                confineToSafeArea: false,
                navBarHeight: 84,
                itemCount: bindings.length,
                bottomScreenMargin: 0,
                customWidget: _buildCustomNavBar(bindings),
              ),
            );
          },
        );
      },
    );
  }
}
