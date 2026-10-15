import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/text/text.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreCatalogView extends ConsumerStatefulWidget {
  const StoreCatalogView({
    super.key,
    required this.kind,
    required this.title,
    this.showPromoBanner = false,
  });

  final StoreKind kind;
  final String title;
  final bool showPromoBanner;

  @override
  ConsumerState<StoreCatalogView> createState() => _StoreCatalogViewState();
}

class _StoreCatalogViewState extends ConsumerState<StoreCatalogView> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode(debugLabel: "storeCatalogSearch");
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scrollController.position.pixels >= max - 400) {
      unawaited(ref.read(storeCatalogProvider(widget.kind)).loadMoreProducts());
    }
  }

  void _dismissSearchKeyboard() {
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod("TextInput.hide");
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(storeCatalogProvider(widget.kind));
    final store = vm.store;
    final title = store == null ? widget.title : vm.displayTitle;

    ref.listen(storeCatalogProvider(widget.kind), (prev, next) {
      final count = next.store?.cartCount;
      if (count == null) return;
      if (prev?.store?.cartCount == count) return;
      ref.read(storeCartStateProvider).syncCount(count);
    });

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissSearchKeyboard,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: DthAppBar(
          title: title,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StoreCartBadgeButton(
                kind: widget.kind,
                countOverride: store?.cartCount,
              ),
            ),
          ],
        ),
        body: vm.loadState.when(
          busy: () =>
              StoreCatalogSkeleton(showPromoBanner: widget.showPromoBanner),
          error: (failure) => _StoreStatusBody(
            title: "Store unavailable",
            message: failure.message,
            onRetry: () => vm.loadStore(forceRefresh: true),
          ),
          idle: () {
            if (store == null) {
              return _StoreStatusBody(
                title: "Store unavailable",
                message: "We couldn't load this store right now.",
                onRetry: () => vm.loadStore(forceRefresh: true),
              );
            }
            if (!store.isOpen) {
              return _StoreStatusBody(
                title: store.name,
                message: store.closedMessage?.trim().isNotEmpty == true
                    ? store.closedMessage!
                    : "This store is not open right now.",
                onRetry: () => vm.loadStore(forceRefresh: true),
              );
            }
            return _StoreOpenBody(
              vm: vm,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              scrollController: _scrollController,
              showPromoBanner: widget.showPromoBanner,
              onDismissKeyboard: _dismissSearchKeyboard,
              onRefresh: () => _refreshCatalog(ref, widget.kind, vm),
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshCatalog(
    WidgetRef ref,
    StoreKind kind,
    StoreCatalogViewModel vm,
  ) async {
    final storeState = ref.read(storeStateProvider);
    final modules = ref.read(appModulesStateProvider).appModules.value;
    await Future.wait([
      vm.refresh(),
      // Keep event store warm so the merch promo banner stays accurate.
      if (kind == StoreKind.merch && modules?.eventStore == true)
        storeState
            .fetch("event", forceRefresh: true)
            .then((_) {}, onError: (_) {}),
    ]);
  }
}

class _StoreStatusBody extends StatelessWidget {
  const _StoreStatusBody({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StoreEmptyState(title: title, message: message),
            Gap.h16,
            AppButton.onBorder(
              text: "Retry",
              isShort: true,
              width: 140,
              press: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreOpenBody extends StatelessWidget {
  const _StoreOpenBody({
    required this.vm,
    required this.searchController,
    required this.searchFocusNode,
    required this.scrollController,
    required this.showPromoBanner,
    required this.onDismissKeyboard,
    required this.onRefresh,
  });

  final StoreCatalogViewModel vm;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ScrollController scrollController;
  final bool showPromoBanner;
  final VoidCallback onDismissKeyboard;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final products = vm.products;
    final showSkeleton = vm.showProductsSkeleton;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          if (showPromoBanner)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: StorePromoBanner(
                  onVisitLiveStores: () {
                    onDismissKeyboard();
                    MobileNavigationService.instance.navigateTo(
                      LiveEventStoresView.path,
                    );
                  },
                ),
              ),
            ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StoreSearchFilterHeaderDelegate(
              categories: vm.categories,
              selectedCategoryId: vm.selectedCategoryId,
              searchController: searchController,
              searchFocusNode: searchFocusNode,
              onSearchChanged: vm.setSearchQuery,
              onCategorySelected: (id) {
                HapticFeedback.selectionClick();
                onDismissKeyboard();
                vm.selectCategory(id);
              },
            ),
          ),
          if (showSkeleton)
            const SliverToBoxAdapter(child: StoreCatalogProductsSkeleton())
          else if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: StoreEmptyState(
                title: vm.hasActiveSearch
                    ? "No Results Found"
                    : "No Product Listed Yet",
                message: vm.hasActiveSearch
                    ? "We couldn't find any items matching your search. Try a different search term."
                    : "There are no items in the store right now. Check back soon for new products.",
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];
                  return StoreProductCard(
                    product: product,
                    onTap: () {
                      onDismissKeyboard();
                      // Warm latest detail (stock / colours) before the sheet opens.
                      unawaited(
                        ProviderScope.containerOf(context)
                            .read(storeStateProvider)
                            .fetchProduct(
                              product.kind.apiStoreId,
                              product.id,
                              forceRefresh: true,
                            )
                            .then<void>((_) {}, onError: (_) {}),
                      );
                      unawaited(showProductDetailSheet(context, product));
                    },
                  );
                }, childCount: products.length),
              ),
            ),
          if (vm.loadingMore)
            const SliverToBoxAdapter(
              child: StoreCatalogProductsSkeleton(itemCount: 2),
            ),
        ],
      ),
    );
  }
}

class _StoreSearchFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StoreSearchFilterHeaderDelegate({
    required this.categories,
    required this.selectedCategoryId,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  final List<StoreCategory> categories;
  final String selectedCategoryId;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;

  static const _height = 118.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AppTextField(
              controller: searchController,
              focusNode: searchFocusNode,
              borderRadius: BorderRadius.circular(100),
              onChanged: onSearchChanged,
              hint: "Search anything...",
              hintColor: AppColors.tint25,
              hintStyle: AppTextStyle.regular.copyWith(fontSize: 16),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => searchFocusNode.unfocus(),
              suffixIcon: SvgPicture.asset(
                SvgAssets.search,
                width: 20,
                height: 20,
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => Gap.w8,
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = category.id == selectedCategoryId;
                return GestureDetector(
                  onTap: () => onCategorySelected(category.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.greyTint20,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: AppText.medium(
                      category.label,
                      fontSize: 14,
                      letterSpacing: -0.4,
                      color: selected ? AppColors.white : AppColors.black,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StoreSearchFilterHeaderDelegate oldDelegate) {
    return selectedCategoryId != oldDelegate.selectedCategoryId ||
        categories != oldDelegate.categories ||
        searchController != oldDelegate.searchController ||
        searchFocusNode != oldDelegate.searchFocusNode;
  }
}
