import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/store.dart";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ShoppingComplexView extends ConsumerStatefulWidget {
  const ShoppingComplexView({super.key});

  static const String path = NavigatorRoutes.shoppingComplex;

  @override
  ConsumerState<ShoppingComplexView> createState() =>
      _ShoppingComplexViewState();
}

class _ShoppingComplexViewState extends ConsumerState<ShoppingComplexView> {
  @override
  void initState() {
    super.initState();
    // Merch catalog loads `/stores/merch`; also warm `/stores/event` so the
    // Live Event promo banner can respect `is_open`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final modules = ref.read(appModulesStateProvider).appModules.value;
      if (modules?.eventStore != true) return;
      unawaited(
        ref
            .read(storeStateProvider)
            .fetch("event")
            .then((_) {}, onError: (_) {}),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(appModulesStateProvider).appModules.value;
    final storeState = ref.watch(storeStateProvider);
    final eventStore = storeState.cached("event");
    // Banner only when the event module is on AND the event store is open.
    final showEventStoreBanner =
        modules?.eventStore == true && eventStore?.isOpen == true;

    return StoreCatalogView(
      kind: StoreKind.merch,
      title: "Shopping Complex",
      showPromoBanner: showEventStoreBanner,
    );
  }
}
