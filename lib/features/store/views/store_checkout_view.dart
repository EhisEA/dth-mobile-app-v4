import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/core/extension/int_extension.dart";
import "package:dth_v4/core/extension/string_extension.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreCheckoutView extends ConsumerStatefulWidget {
  const StoreCheckoutView({super.key, required this.kind});

  static const String path = NavigatorRoutes.storeCheckout;

  final StoreKind kind;

  @override
  ConsumerState<StoreCheckoutView> createState() => _StoreCheckoutViewState();
}

class _StoreCheckoutViewState extends ConsumerState<StoreCheckoutView> {
  late final TextEditingController _promoController;

  @override
  void initState() {
    super.initState();
    _promoController = TextEditingController();
    final checkout = ref.read(storeCheckoutViewModelProvider);
    final promo = checkout.promoCode;
    if (promo != null && promo.isNotEmpty) {
      _promoController.text = promo;
    }
    // Fallback if opened without a quote (e.g. deep link).
    if (checkout.quote == null || checkout.kind != widget.kind) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final addressUid = ref.read(cartViewModelProvider).shippingAddress?.uid;
        unawaited(
          ref
              .read(storeCheckoutViewModelProvider)
              .load(widget.kind, addressUid: addressUid),
        );
      });
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  String _formatAmount(String value, String symbol, {bool discount = false}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return "${discount ? "-" : ""}${symbol}0";
    try {
      final formatted = trimmed.toMoney();
      return "${discount ? "-" : ""}$symbol$formatted";
    } catch (_) {
      return "${discount ? "-" : ""}$symbol$trimmed";
    }
  }

  StoreShippingAddress? _displayAddress(
    StoreCheckoutQuote? quote,
    StoreShippingAddress? local,
  ) {
    final fromQuote = quote?.address;
    if (fromQuote != null) return fromQuote.toShippingAddress();
    return local;
  }

  String _itemSubtitle(StoreCartItem item) {
    if (widget.kind == StoreKind.merch) {
      final sizeLabel = item.variant.size.trim();
      final colorName = item.variant.color?.name.trim() ?? "";
      final parts = [
        if (sizeLabel.isNotEmpty) sizeLabel,
        if (colorName.isNotEmpty) colorName,
      ];
      if (parts.isNotEmpty) return parts.join(" · ");
    }
    return item.product.vendor;
  }

  Future<void> _refreshQuoteAfterAddressChange() async {
    if (!mounted) return;
    final cart = ref.read(cartViewModelProvider);
    final checkout = ref.read(storeCheckoutViewModelProvider);
    await checkout.onAddressChanged(addressUid: cart.shippingAddress?.uid);
    final quoted = checkout.quote?.address;
    if (quoted != null) {
      cart.setShippingAddress(quoted.toShippingAddress());
    }
  }

  Future<void> _openAddShippingAddress() async {
    HapticFeedback.selectionClick();
    await MobileNavigationService.instance.navigateTo(
      StoreShippingAddressView.path,
    );
    await _refreshQuoteAfterAddressChange();
  }

  Future<void> _openEditShippingAddress(StoreShippingAddress address) async {
    HapticFeedback.selectionClick();
    final uid = address.uid?.trim();
    await MobileNavigationService.instance.navigateTo(
      StoreShippingAddressView.path,
      extra: {
        if (uid != null && uid.isNotEmpty)
          RoutingArgumentKey.storeAddressUid: uid,
      },
    );
    await _refreshQuoteAfterAddressChange();
  }

  Future<void> _openAddressesList() async {
    HapticFeedback.selectionClick();
    await showAddressesSheet(context);
    await _refreshQuoteAfterAddressChange();
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(storeCheckoutViewModelProvider);
    final cart = ref.watch(cartViewModelProvider);
    final quote = checkout.quote;
    final items = quote?.items ?? const <StoreCartItem>[];
    final currencySymbol = quote?.currencySymbol ?? "₦";
    final address = _displayAddress(quote, cart.shippingAddress);
    final busy = checkout.isQuoteBusy && quote == null;
    final totalLabel = quote == null
        ? "Checkout"
        : "Checkout ${_formatAmount(quote.total.value, currencySymbol)}";
    final canPay = checkout.canCheckout && !checkout.isQuoteBusy;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const DthAppBar(title: "Checkout"),
      body: Column(
        children: [
          Expanded(
            child: busy
                ? const Center(child: CircularProgressIndicator.adaptive())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AppText.medium(
                          "Your Cart",
                          fontSize: 16,
                          color: AppColors.mainBlack,
                        ),
                      ),
                      Gap.h16,
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AppText.regular(
                            "No selected items to checkout.",
                            fontSize: 14,
                            color: AppColors.tint15,
                          ),
                        )
                      else
                        ...items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final problem = item.problem?.trim();
                          final unavailable =
                              problem != null && problem.isNotEmpty;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index > 0)
                                  Container(
                                    height: 1,
                                    color: AppColors.greyTint15,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: SizedBox(
                                            width: 91,
                                            height: 80,
                                            child:
                                                item.product.imageUrl
                                                    .trim()
                                                    .isEmpty
                                                ? ColoredBox(
                                                    color: AppColors.greyTint20,
                                                  )
                                                : CachedNetworkImage(
                                                    imageUrl:
                                                        item.product.imageUrl,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) =>
                                                        ColoredBox(
                                                          color: AppColors
                                                              .greyTint20,
                                                        ),
                                                    errorWidget: (_, __, ___) =>
                                                        ColoredBox(
                                                          color: AppColors
                                                              .greyTint20,
                                                        ),
                                                  ),
                                          ),
                                        ),
                                        Gap.w16,
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        AppText.medium(
                                                          item.product.name,
                                                          fontSize: 16,
                                                          color: AppColors
                                                              .mainBlack,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        Gap.h4,
                                                        AppText.medium(
                                                          _itemSubtitle(item),
                                                          fontSize: 12,
                                                          color: AppColors
                                                              .blackTint20,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.transparent,
                                                      border: Border.all(
                                                        color: AppColors
                                                            .greyTint35,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: AppText.medium(
                                                      "x${item.quantity}",
                                                      fontSize: 14,
                                                      color: AppColors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (unavailable) ...[
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xffFDECEC,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              100,
                                                            ),
                                                      ),
                                                      child: AppText.medium(
                                                        problem,
                                                        fontSize: 10,
                                                        color:
                                                            AppColors.redTint35,
                                                      ),
                                                    ),
                                                    Gap.h4,
                                                  ],
                                                  AppText.bold(
                                                    "$currencySymbol${item.lineTotal.toMoneyWholeNumber()}",
                                                    fontSize: 16,
                                                    color: const Color(
                                                      0xff006B34,
                                                    ),
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
                              ],
                            ),
                          );
                        }),
                      Gap.h16,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AppText.medium(
                          "Promo Code",
                          fontSize: 16,
                          color: AppColors.mainBlack,
                        ),
                      ),
                      Gap.h8,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyTint30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _promoController,
                                enabled: !checkout.isQuoteBusy,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  hintText: "Enter promo code",
                                  hintStyle: AppTextStyle.regular.copyWith(
                                    fontSize: 14,
                                    letterSpacing: -0.2,
                                    color: AppColors.tint15,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: checkout.isQuoteBusy
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      unawaited(
                                        checkout.applyPromo(
                                          _promoController.text,
                                        ),
                                      );
                                    },
                              child: AppText.semiBold(
                                "|    Apply",
                                fontSize: 14,
                                color: const Color(0xff002914),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (quote?.promo?.applied == false &&
                          quote?.promo?.message?.trim().isNotEmpty == true) ...[
                        Gap.h8,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AppText.regular(
                            quote!.promo!.message!,
                            fontSize: 12,
                            color: AppColors.redTint35,
                          ),
                        ),
                      ],
                      if (quote?.requiresAddress == true) ...[
                        Gap.h24,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AppText.medium(
                            "Shipping Address",
                            fontSize: 16,
                            color: AppColors.mainBlack,
                          ),
                        ),
                        Gap.h8,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: address == null
                              ? _EmptyShippingAddressCard(
                                  onAdd: () =>
                                      unawaited(_openAddShippingAddress()),
                                )
                              : _FilledShippingAddressCard(
                                  address: address,
                                  onEdit: () => unawaited(
                                    _openEditShippingAddress(address),
                                  ),
                                  onOpenAddresses: () =>
                                      unawaited(_openAddressesList()),
                                ),
                        ),
                        if (address == null) ...[
                          Gap.h8,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AppText.regular(
                              "Add a delivery address to continue checkout.",
                              fontSize: 12,
                              color: AppColors.redTint35,
                            ),
                          ),
                        ],
                      ],
                      Gap.h16,
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              ImageAssets.storePaymentSummaryBg,
                            ),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.medium(
                                "Payment Summary",
                                fontSize: 16,
                                color: AppColors.mainBlack,
                              ),
                              Gap.h16,
                              if (quote == null)
                                AppText.regular(
                                  checkout.isQuoteBusy
                                      ? "Loading summary…"
                                      : "Summary unavailable.",
                                  fontSize: 14,
                                  color: AppColors.tint15,
                                )
                              else ...[
                                for (
                                  var i = 0;
                                  i < quote.summary.length;
                                  i++
                                ) ...[
                                  if (i > 0) Gap.h16,
                                  _SummaryRow(
                                    label: quote.summary[i].label,
                                    value: _formatAmount(
                                      quote.summary[i].value,
                                      currencySymbol,
                                      discount: quote.summary[i].isDiscount,
                                    ),
                                  ),
                                ],
                                Gap.h26,
                                _SummaryRow(
                                  label: quote.total.label,
                                  value: _formatAmount(
                                    quote.total.value,
                                    currencySymbol,
                                  ),
                                  bold: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: AppButton(
              text: quote?.hasItemProblems == true ? "Edit cart" : totalLabel,
              enabled: quote?.hasItemProblems == true
                  ? !checkout.isPlacingOrder
                  : canPay && !checkout.isPlacingOrder,
              isLoading:
                  checkout.isPlacingOrder ||
                  (checkout.isQuoteBusy && quote != null),
              disableTextColor: AppColors.tint10,
              press: quote?.hasItemProblems == true
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    }
                  : canPay && !checkout.isPlacingOrder
                  ? () {
                      HapticFeedback.lightImpact();
                      unawaited(checkout.placeOrder());
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyShippingAddressCard extends StatelessWidget {
  const _EmptyShippingAddressCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 24, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyTint30),
      ),
      child: Row(
        children: [
          SvgPicture.asset(SvgAssets.deliveryTruck, width: 20, height: 20),
          Gap.w16,
          Expanded(
            child: AppText.regular(
              "No delivery address added yet",
              fontSize: 14,
              color: AppColors.tint15,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Gap.w8,
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(100),
              ),
              child: AppText.medium(
                "Add",
                fontSize: 14,
                height: 1,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilledShippingAddressCard extends StatelessWidget {
  const _FilledShippingAddressCard({
    required this.address,
    required this.onEdit,
    required this.onOpenAddresses,
  });

  final StoreShippingAddress address;
  final VoidCallback onEdit;
  final VoidCallback onOpenAddresses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onOpenAddresses,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyTint30),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    SvgAssets.deliveryTruck,
                    width: 20,
                    height: 20,
                  ),
                  Gap.w10,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.medium(
                          address.primaryLine,
                          fontSize: 14,
                          color: AppColors.black,
                          maxLines: 1,
                          height: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Gap.h4,
                        AppText.regular(
                          address.secondaryLine,
                          fontSize: 12,
                          color: AppColors.tint25,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Gap.w8,
                  SvgPicture.asset(
                    SvgAssets.downArrow,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      AppColors.tint15,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Gap.h10,
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.greyTint30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, size: 14, color: AppColors.mainBlack),
                Gap.w6,
                AppText.medium(
                  "Edit",
                  fontSize: 13,
                  color: AppColors.mainBlack,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: bold
              ? AppText.medium(
                  label,
                  fontSize: 16,
                  color: const Color(0xff151515),
                )
              : AppText.medium(label, fontSize: 14, color: AppColors.tint25),
        ),
        bold
            ? AppText.semiBold(
                value,
                fontSize: 18,
                color: const Color(0xff1b1b1b),
              )
            : AppText.semiBold(
                value,
                fontSize: 16,
                color: AppColors.tertiary60,
              ),
      ],
    );
  }
}
