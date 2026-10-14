import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/store/store.dart";

import "package:flutter/material.dart";

class LiveEventStoresView extends StatelessWidget {
  const LiveEventStoresView({super.key});

  static const String path = NavigatorRoutes.liveEventStores;

  @override
  Widget build(BuildContext context) {
    return const StoreCatalogView(
      kind: StoreKind.liveEvent,
      title: "Live Event Stores",
    );
  }
}
