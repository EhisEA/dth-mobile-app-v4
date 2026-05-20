import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/notifications/bottomsheet/show_mark_all_read_sheet.dart";
import "package:dth_v4/features/notifications/components/notification_list_skeleton.dart";
import "package:dth_v4/features/notifications/components/notification_tile.dart";
import "package:dth_v4/features/notifications/components/notifications_empty_state.dart";
import "package:dth_v4/features/notifications/view_model/notifications_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  static const String path = NavigatorRoutes.notifications;

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(notificationsViewModelProvider).loadFirstPage());
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scrollController.position.pixels >= max - 400) {
      unawaited(ref.read(notificationsViewModelProvider).loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(notificationsViewModelProvider);
    final showMarkAll =
        vm.hasUnread && vm.baseState.isIdle && vm.items.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: DthAppBar(
        title: "Notifications",
        actions: showMarkAll
            ? [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    unawaited(showMarkAllNotificationsReadSheet(context, ref));
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: SvgPicture.asset(SvgAssets.notificationsMarkAllRead),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: vm.baseState.when(
          busy: () => const NotificationListSkeleton(),
          error: (Failure failure) => Center(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              children: [
                Gap.h24,
                AppText.semiBold(
                  "Could not load notifications",
                  fontSize: 16,
                  color: AppColors.mainBlack,
                  textAlign: TextAlign.center,
                ),
                Gap.h12,
                AppText.regular(
                  failure.message,
                  fontSize: 14,
                  color: AppColors.blackTint20,
                  textAlign: TextAlign.center,
                  multiText: true,
                ),
                Gap.h24,
                Center(
                  child: AppButton.primary(
                    text: "Retry",
                    height: 48,
                    press: () => unawaited(vm.loadFirstPage()),
                  ),
                ),
              ],
            ),
          ),
          idle: () {
            if (vm.items.isEmpty) {
              return const NotificationsEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () => vm.refresh(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: vm.items.length + (vm.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= vm.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  }
                  final item = vm.items[index];
                  return NotificationTile(
                    item: item,
                    onTap: () => unawaited(vm.markAsRead(item.uid)),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
