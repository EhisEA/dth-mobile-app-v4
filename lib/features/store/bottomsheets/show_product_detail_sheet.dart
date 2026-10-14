import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/int_extension.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showProductDetailSheet(
  BuildContext context,
  StoreProduct product,
) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    margin: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(48),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      reverseDuration: Duration(milliseconds: 280),
      reverseCurve: Curves.easeInCubic,
    ),
    builder: (_) =>
        _SheetTransition(child: _ProductDetailSheet(product: product)),
  );
}

/// Softens the sheet body as the route animates in/out.
class _SheetTransition extends StatelessWidget {
  const _SheetTransition({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _ProductDetailSheet extends ConsumerStatefulWidget {
  const _ProductDetailSheet({required this.product});

  final StoreProduct product;

  @override
  ConsumerState<_ProductDetailSheet> createState() =>
      _ProductDetailSheetState();
}

class _ProductDetailSheetState extends ConsumerState<_ProductDetailSheet> {
  late StoreProduct _product;
  late int _qty;
  String? _selectedSize;
  String? _selectedColor;
  int _imageIndex = 0;
  bool _detailLoading = false;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _qty = 1;
    _selectedSize = _product.sizes.isEmpty ? null : _product.sizes.first;
    _selectedColor = _product.colors.isEmpty
        ? null
        : _product.colors.first.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadDetail());
    });
  }

  Future<void> _loadDetail() async {
    final storeState = ref.read(storeStateProvider);
    final cached = storeState.cachedProductDetail(
      _product.kind.apiStoreId,
      _product.id,
    );
    if (cached != null) {
      _applyDetail(cached);
      return;
    }

    setState(() {
      _detailLoading = true;
      _detailError = null;
    });

    try {
      final result = await storeState.fetchProduct(
        _product.kind.apiStoreId,
        _product.id,
      );
      if (!mounted) return;
      _applyDetail(result);
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _detailLoading = false;
        _detailError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailLoading = false;
        _detailError = e.toString();
      });
    }
  }

  void _applyDetail(StoreProductDetailResult result) {
    final detailed = StoreProduct.fromDetail(
      result.product,
      kind: _product.kind,
      currencyCode: result.currency.code,
      currencySymbol: result.currency.symbol.isNotEmpty
          ? result.currency.symbol
          : _product.currencySymbol,
    );

    final size = _selectedSize;
    final preferredSize = (size != null && detailed.sizes.contains(size))
        ? size
        : (detailed.sizes.isEmpty ? null : detailed.sizes.first);

    final color = _selectedColor;
    final colorNames = detailed.colors.map((c) => c.name).toList();
    final preferredColor = (color != null && colorNames.contains(color))
        ? color
        : (colorNames.isEmpty ? null : colorNames.first);

    final resolved = detailed.resolveVariant(
      size: preferredSize,
      colorName: preferredColor,
    );

    setState(() {
      _product = detailed;
      _selectedSize = resolved?.size ?? preferredSize;
      _selectedColor = resolved?.color?.name ?? preferredColor;
      _detailLoading = false;
      _detailError = null;
      _qty = _clampedQty(_qty);
    });
  }

  StoreProductVariant? get _selectedVariant =>
      _product.resolveVariant(size: _selectedSize, colorName: _selectedColor);

  int? get _maxQty {
    final maxOrder = _product.maxPerOrder;
    final available = _selectedVariant?.available;
    if (maxOrder == null && available == null) return null;
    if (maxOrder == null) return available;
    if (available == null) return maxOrder;
    return maxOrder < available ? maxOrder : available;
  }

  int _clampedQty(int value) {
    final max = _maxQty;
    if (max == null) return value < 1 ? 1 : value;
    if (max < 1) return 1;
    if (value < 1) return 1;
    if (value > max) return max;
    return value;
  }

  Color _parseHex(String hex) {
    var value = hex.trim();
    if (value.startsWith("#")) value = value.substring(1);
    if (value.length == 3) {
      value = value.split("").map((c) => "$c$c").join();
    }
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return AppColors.greyTint35;
    return Color(0xFF000000 | parsed);
  }

  bool _isLightColor(Color color) => color.computeLuminance() > 0.85;

  void _selectSize(String size) {
    setState(() {
      _selectedSize = size;
      _qty = _clampedQty(_qty);
    });
  }

  void _selectColor(String colorName) {
    setState(() {
      _selectedColor = colorName;
      _qty = _clampedQty(_qty);
    });
  }

  Future<void> _addToCart() async {
    final variant = _selectedVariant;
    if (_product.soldOut) return;
    if (_product.variants.isNotEmpty &&
        (variant == null || !variant.isAvailable)) {
      DthFlushBar.instance.showError(
        title: "Store",
        message: "That size and colour combination is unavailable.",
      );
      return;
    }
    final variantUid = variant?.uid.trim() ?? "";
    if (variantUid.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Store",
        message: "Select a size to continue.",
      );
      return;
    }

    final cartState = ref.read(storeCartStateProvider);
    if (cartState.adding) return;

    HapticFeedback.lightImpact();
    try {
      await cartState.addItem(variantUid: variantUid, quantity: _qty);
      if (!mounted) return;
      ref
          .read(cartViewModelProvider)
          .addToCart(
            product: _product,
            quantity: _qty,
            selectedSize: _selectedSize,
            selectedColor: _selectedColor,
            variantUid: variantUid,
          );
      Navigator.of(context).pop();
      DthFlushBar.instance.showSuccess(
        title: "Cart",
        message: "${_product.title} added to cart.",
      );
    } on ApiFailure catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(title: "Cart", message: e.message);
    } catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(title: "Cart", message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final discount = _product.discountPercent;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.80;
    final images = _product.galleryImages;
    final variant = _selectedVariant;
    final cartAdding = ref.watch(storeCartStateProvider).adding;
    final canAdd =
        !_product.soldOut &&
        (_product.variants.isEmpty || (variant?.isAvailable ?? false));

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Gap.h12,
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.greyTint30,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    Gap.h12,
                    AspectRatio(
                      aspectRatio: 1.9,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (images.isEmpty)
                                ColoredBox(color: AppColors.greyTint20)
                              else
                                PageView.builder(
                                  itemCount: images.length,
                                  onPageChanged: (i) =>
                                      setState(() => _imageIndex = i),
                                  itemBuilder: (_, i) => CachedNetworkImage(
                                    imageUrl: images[i],
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        ColoredBox(color: AppColors.greyTint20),
                                    errorWidget: (_, __, ___) =>
                                        ColoredBox(color: AppColors.greyTint20),
                                  ),
                                ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x00000000),
                                      Color(0xFF000000),
                                    ],
                                  ),
                                ),
                              ),
                              if (_product.soldOut)
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.redTint35,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: AppText.semiBold(
                                      "Sold-Out",
                                      fontSize: 11,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              if (images.length > 1)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 64,
                                  child: _PageDots(
                                    count: images.length,
                                    current: _imageIndex,
                                  ),
                                ),
                              Positioned(
                                left: 24,
                                right: 24,
                                bottom: 16,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: AppText.semiBold(
                                                  _product.title,
                                                  fontSize: 16,
                                                  color: AppColors.white,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (discount != null &&
                                                  !_product.soldOut) ...[
                                                Gap.w8,
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xffFFF3E5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          40,
                                                        ),
                                                  ),
                                                  child: AppText.bold(
                                                    "-$discount%",
                                                    fontSize: 8,
                                                    color: AppColors.redTint35,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Gap.h(2),
                                          AppText.medium(
                                            _product.storeName,
                                            fontSize: 12,
                                            color: const Color(0xffC9D1E1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        AppText.bold(
                                          "${_product.currencySymbol}${_product.price.toMoneyWholeNumber()}",
                                          fontSize: 20,
                                          height: 1,
                                          color: AppColors.white,
                                        ),
                                        if (_product.originalPrice != null)
                                          AppText.medium(
                                            "${_product.currencySymbol}${_product.originalPrice!.toMoneyWholeNumber()}",
                                            fontSize: 12,
                                            color: const Color(0xffABB1C4),
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_detailLoading &&
                              _product.description.isEmpty &&
                              _product.variants.isEmpty) ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_detailError != null) ...[
                            AppText.medium(
                              _detailError!,
                              fontSize: 13,
                              color: AppColors.redTint35,
                              multiText: true,
                            ),
                            Gap.h12,
                            AppButton.onBorder(
                              text: "Retry",
                              isShort: true,
                              width: 120,
                              press: () => unawaited(_loadDetail()),
                            ),
                            Gap.h16,
                          ],
                          if (_product.description.trim().isNotEmpty) ...[
                            AppText.semiBold(
                              "Description",
                              fontSize: 16,
                              color: AppColors.black,
                            ),
                            Gap.h8,
                            AppText.regular(
                              _product.description,
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.tint30,
                              multiText: true,
                            ),
                          ],
                          if ((_product.terms ?? _product.sponsorshipTerms) !=
                              null) ...[
                            Gap.h20,
                            AppText.medium(
                              "Sponsorship Terms",
                              fontSize: 16,
                              color: AppColors.tertiary60,
                            ),
                            Gap.h8,
                            AppText.regular(
                              (_product.terms ?? _product.sponsorshipTerms)!,
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.blackTint20,
                              multiText: true,
                            ),
                          ],
                          if (_product.sizes.isNotEmpty) ...[
                            Gap.h24,
                            AppText.semiBold(
                              "Select Size",
                              fontSize: 16,
                              height: 1,
                              color: AppColors.black,
                            ),
                            Gap.h8,
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _product.sizes.map((size) {
                                final selected = size == _selectedSize;
                                final available = _product.hasAvailableSize(
                                  size,
                                );
                                return _SizeChip(
                                  label: storeSizeDisplayLabel(size),
                                  selected: selected,
                                  available: available,
                                  onTap: !available || _product.soldOut
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          _selectSize(size);
                                        },
                                );
                              }).toList(),
                            ),
                          ],
                          if (_product.colors.isNotEmpty) ...[
                            Gap.h24,
                            AppText.semiBold(
                              "Select Color",
                              fontSize: 16,
                              height: 1,
                              color: AppColors.black,
                            ),
                            Gap.h8,
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _product.colors.map((color) {
                                final selected = color.name == _selectedColor;
                                final available = _product.hasAvailableColor(
                                  color.name,
                                );
                                final fill = _parseHex(color.hex);
                                return _ColorChip(
                                  fill: fill,
                                  selected: selected,
                                  available: available,
                                  lightBorder: _isLightColor(fill),
                                  onTap: !available || _product.soldOut
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          _selectColor(color.name);
                                        },
                                );
                              }).toList(),
                            ),
                          ],
                          Gap.h24,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  );
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(fade),
                      child: child,
                    ),
                  );
                },
                child: !canAdd
                    ? KeyedSubtree(
                        key: ValueKey(
                          _product.soldOut ? "sold-out" : "unavailable",
                        ),
                        child: AppButton(
                          text: _product.soldOut
                              ? "Item is sold out"
                              : "Unavailable",
                          enabled: false,
                          color: AppColors.greyTint25,
                          textColor: AppColors.greyTint55,
                          press: null,
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey("add-to-cart"),
                        child: Row(
                          children: [
                            IgnorePointer(
                              ignoring: cartAdding,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                opacity: cartAdding ? 0.5 : 1,
                                child: _QtyStepper(
                                  qty: _qty,
                                  onMinus: () {
                                    if (_qty <= 1) return;
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _qty = _clampedQty(_qty - 1),
                                    );
                                  },
                                  onPlus: () {
                                    final max = _maxQty;
                                    if (max != null && _qty >= max) return;
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _qty = _clampedQty(_qty + 1),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Gap.w12,
                            Expanded(
                              child: AppButton.primary(
                                text: "Add to cart",
                                isLoading: cartAdding,
                                enabled: !cartAdding,
                                press: () => unawaited(_addToCart()),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.available,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool available;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: available ? 1 : 0.4,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          scale: selected ? 1.06 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.mainBlack.withValues(alpha: 0.04)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.mainBlack : AppColors.greyTint35,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: AppText.medium(
              label,
              fontSize: 16,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: available ? AppColors.black : AppColors.greyTint50,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.fill,
    required this.selected,
    required this.available,
    required this.lightBorder,
    this.onTap,
  });

  final Color fill;
  final bool selected;
  final bool available;
  final bool lightBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: available ? 1 : 0.35,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          scale: selected ? 1.08 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.mainBlack : Colors.transparent,
                width: selected ? 1.6 : 0,
              ),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 28 : 28,
              height: selected ? 28 : 28,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: lightBorder
                      ? AppColors.greyTint50
                      : AppColors.greyTint35,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: i == current ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i == current ? AppColors.primary : const Color(0xFFFCFCFC),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff121212).withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          icon: Icons.remove,
          background: AppColors.tint40,
          onTap: onMinus,
        ),
        Gap.w8,
        Container(
          width: 44,
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.greyTint35),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
                  child: child,
                ),
              );
            },
            child: AppText.medium(
              "$qty",
              key: ValueKey(qty),
              fontSize: 16,
              color: AppColors.black,
            ),
          ),
        ),
        Gap.w8,
        _RoundIconButton(
          icon: Icons.add,
          background: AppColors.primary,
          onTap: onPlus,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: AppColors.white),
      ),
    );
  }
}
