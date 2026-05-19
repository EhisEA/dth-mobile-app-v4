import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/tickets/components/purchase_ticket_item.dart";
import "package:dth_v4/features/tickets/components/ticket_empty_state.dart";
import "package:dth_v4/features/tickets/view_model/purchase_tickets_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class PurchaseTicketsView extends ConsumerStatefulWidget {
  const PurchaseTicketsView({
    super.key,
    required this.eventUid,
    this.onPurchaseSuccess,
  });

  static const String path = NavigatorRoutes.purchaseTickets;

  final String eventUid;
  final Future<void> Function()? onPurchaseSuccess;

  @override
  ConsumerState<PurchaseTicketsView> createState() =>
      _PurchaseTicketsViewState();
}

class _PurchaseTicketsViewState extends ConsumerState<PurchaseTicketsView> {
  static const String _subtitle =
      "Event tickets covers your gate pass, seat reservation and refreshments at the show";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(purchaseTicketsViewModelProvider(widget.eventUid))
          .bindOnPurchaseSuccess(widget.onPurchaseSuccess);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(purchaseTicketsViewModelProvider(widget.eventUid));
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Loader.page(
      isLoading: vm.checkoutState.isBusy && vm.tickets.isNotEmpty,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: const DthAppBar(title: "Purchase Tickets"),
        body: vm.baseState.when(
          busy: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (failure) => ListView(
            padding: EdgeInsets.zero,
            children: [
              Gap.h32,
              TicketEmptyState(
                title: "Could not load tickets",
                subtitle: failure.message,
                onRetry: () => unawaited(vm.refresh()),
              ),
            ],
          ),

          idle: () {
            final tickets = vm.tickets;
            final hasSelection = vm.hasSelection;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: AppText.regular(
                    _subtitle,
                    fontSize: 14,
                    color: AppColors.tint25,
                    multiText: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: AppText.semiBold(
                    "Available Tickets",
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
                Expanded(
                  child: tickets.isEmpty
                      ? ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            Gap.h32,
                            const TicketEmptyState(
                              title: "Tickets Not Available Yet",
                              subtitle:
                                  "Ticket sales haven't started yet. Please check back later for updates.",
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: tickets.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: AppColors.greyTint30),
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            final quantity = vm.quantityFor(ticket.uid);
                            return PurchaseTicketItem(
                              ticket: ticket,
                              quantity: quantity,
                              onIncrement: () => vm.increment(ticket.uid),
                              onDecrement: () => vm.decrement(ticket.uid),
                            );
                          },
                        ),
                ),
                if (hasSelection)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 12 + bottomInset,
                    ),
                    child: AppButton.primary(
                      height: 52,
                      // isLoading: vm.isBaseBusy,
                      text: "Pay ${vm.formattedTotal} now",
                      press: () => unawaited(vm.checkout()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
