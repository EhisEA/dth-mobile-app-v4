import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:shimmer/shimmer.dart";

Future<StoreCheckoutAddress?> showAddressesSheet(BuildContext context) {
  return showBlurredModalBottomSheet<StoreCheckoutAddress>(
    context: context,
    useRootNavigator: true,
    margin: const EdgeInsets.all(16),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => const _AddressesSheetBody(),
  );
}

class _AddressesSheetBody extends ConsumerStatefulWidget {
  const _AddressesSheetBody();

  @override
  ConsumerState<_AddressesSheetBody> createState() =>
      _AddressesSheetBodyState();
}

class _AddressesSheetBodyState extends ConsumerState<_AddressesSheetBody> {
  String? _deletingUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cold load only — cached list is shown immediately on reopen.
      unawaited(ref.read(storeAddressesStateProvider).fetchAddresses());
    });
  }

  Future<void> _openAddAddress() async {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    await MobileNavigationService.instance.navigateTo(
      StoreShippingAddressView.path,
    );
    if (!mounted) return;
    await ref.read(storeAddressesStateProvider).refreshQuiet();
  }

  void _selectAddress(StoreCheckoutAddress address) {
    HapticFeedback.selectionClick();
    ref
        .read(cartViewModelProvider)
        .setShippingAddress(address.toShippingAddress());
    Navigator.of(context).pop(address);
  }

  Future<bool> _confirmAndDelete(StoreCheckoutAddress address) async {
    final ok = await showDeleteAddressSheet(context);
    if (!ok || !mounted) return false;

    setState(() => _deletingUid = address.uid);
    final addressesState = ref.read(storeAddressesStateProvider);
    try {
      await ref.read(storeRepositoryProvider).deleteAddress(address.uid);
      if (!mounted) return false;

      final selectedUid = ref.read(cartViewModelProvider).shippingAddress?.uid;
      addressesState.removeLocally(address.uid);

      if (selectedUid == address.uid) {
        final next = addressesState.addresses.isNotEmpty
            ? addressesState.addresses.first
            : null;
        ref
            .read(cartViewModelProvider)
            .setShippingAddress(next?.toShippingAddress());
      }

      setState(() => _deletingUid = null);
      DthFlushBar.instance.showSuccess(
        title: "Address",
        message: "Address deleted.",
      );
      unawaited(addressesState.refreshQuiet());
      return false;
    } on ApiFailure catch (e) {
      if (!mounted) return false;
      setState(() => _deletingUid = null);
      DthFlushBar.instance.showError(title: "Address", message: e.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _deletingUid = null);
      DthFlushBar.instance.showError(
        title: "Address",
        message: "Could not delete address. Please try again.",
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesState = ref.watch(storeAddressesStateProvider);
    final addresses = addressesState.addresses;
    final selectedUid = ref.watch(cartViewModelProvider).shippingAddress?.uid;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    final showShimmer =
        addressesState.loadState.isBusy && !addressesState.hasLoaded;
    final error = addressesState.loadState.maybeWhen(
      error: (f) => f.message,
      orElse: () => null,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Material(
        color: AppColors.white,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gap.h12,
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyTint30,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Gap.h16,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppText.medium(
                    "Delivery Addresses",
                    fontSize: 18,
                    color: AppColors.mainBlack,
                  ),
                ),
              ),
              Gap.h12,
              Flexible(
                child: _buildBody(
                  addresses: addresses,
                  selectedUid: selectedUid,
                  showShimmer: showShimmer,
                  error: error,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AppButton.primary(
                  text: "Add new address",
                  press: addresses.length >= 5
                      ? () {
                          DthFlushBar.instance.showError(
                            title: "Address limit",
                            message:
                                "You can save a maximum of 5 addresses. Delete one to add a new address.",
                          );
                        }
                      : () => unawaited(_openAddAddress()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required List<StoreCheckoutAddress> addresses,
    required String? selectedUid,
    required bool showShimmer,
    required String? error,
  }) {
    if (showShimmer) {
      return const _AddressesShimmer();
    }

    if (error != null && addresses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.medium(
              "Couldn't load addresses",
              fontSize: 16,
              color: AppColors.mainBlack,
            ),
            Gap.h8,
            AppText.regular(
              error,
              fontSize: 13,
              color: AppColors.tint15,
              textAlign: TextAlign.center,
            ),
            Gap.h16,
            AppButton.onBorder(
              text: "Retry",
              isShort: true,
              width: 140,
              press: () => unawaited(
                ref
                    .read(storeAddressesStateProvider)
                    .fetchAddresses(force: true),
              ),
            ),
          ],
        ),
      );
    }

    if (addresses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(SvgAssets.deliveryTruck, width: 40, height: 40),
            Gap.h16,
            AppText.medium(
              "No addresses yet",
              fontSize: 16,
              color: AppColors.mainBlack,
            ),
            Gap.h8,
            AppText.regular(
              "Add a delivery address to continue checkout.",
              fontSize: 13,
              color: AppColors.tint15,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: addresses.length,
      separatorBuilder: (_, __) => Gap.h12,
      itemBuilder: (context, index) {
        final address = addresses[index];
        final selected = selectedUid != null && selectedUid == address.uid;
        final deleting = _deletingUid == address.uid;

        return Dismissible(
          key: ValueKey(address.uid),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmAndDelete(address),
          background: const SizedBox.shrink(),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.redTint35,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              SvgAssets.delete,
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          child: _AddressTile(
            address: address,
            selected: selected,
            busy: deleting,
            onTap: () => _selectAddress(address),
          ),
        );
      },
    );
  }
}

class _AddressesShimmer extends StatelessWidget {
  const _AddressesShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.baseShimmer(context),
      highlightColor: AppColors.hightlightShimmer(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.baseShimmer(context),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final StoreCheckoutAddress address;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shipping = address.toShippingAddress();

    return Opacity(
      opacity: busy ? 0.55 : 1,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.greyTint30,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Row(
                        children: [
                          Expanded(
                            child: AppText.medium(
                              shipping.primaryLine,
                              fontSize: 14,
                              color: AppColors.black,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (address.isDefault) ...[
                            Gap.w6,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffE8F7EE),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: AppText.medium(
                                "Default",
                                fontSize: 10,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Gap.h4,
                      AppText.regular(
                        address.formatted.isNotEmpty
                            ? address.formatted
                            : shipping.secondaryLine,
                        fontSize: 12,
                        color: AppColors.tint25,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
