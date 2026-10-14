import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/orders/components/components.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class MyOrdersView extends ConsumerStatefulWidget {
  const MyOrdersView({super.key});

  static const String path = NavigatorRoutes.myOrders;

  @override
  ConsumerState<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends ConsumerState<MyOrdersView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(ordersStateProvider).fetch());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels >= max - 400) {
      unawaited(ref.read(ordersStateProvider).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersStateProvider);
    final groups = ordersState.groups;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const DthAppBar(title: "My Orders"),
      body: ordersState.loadState.when(
        busy: () => const OrdersListSkeleton(),
        error: (failure) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StoreEmptyState(
                  title: "Couldn't load orders",
                  message: failure.message,
                ),
                Gap.h16,
                AppButton.onBorder(
                  text: "Retry",
                  isShort: true,
                  width: 140,
                  press: () => unawaited(ordersState.fetch()),
                ),
              ],
            ),
          ),
        ),
        idle: () {
          if (ordersState.orders.isEmpty) {
            return const OrdersEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ordersState.fetch(quiet: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: groups.length + (ordersState.loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= groups.length) {
                  return const OrdersLoadMoreSkeleton();
                }

                final group = groups[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (index > 0) Gap.h14,
                    Center(
                      child: AppText.medium(
                        group.label,
                        fontSize: 12,
                        color: AppColors.blackTint20,
                      ),
                    ),
                    Gap.h12,
                    for (var i = 0; i < group.orders.length; i++) ...[
                      if (i > 0) Gap.h12,
                      OrderCard(order: group.orders[i]),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
