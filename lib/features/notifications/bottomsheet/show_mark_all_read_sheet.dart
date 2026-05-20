import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/notifications/view_model/notifications_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showMarkAllNotificationsReadSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    builder: (sheetContext) =>
        _MarkAllReadSheetBody(sheetContext: sheetContext),
  );
}

class _MarkAllReadSheetBody extends ConsumerWidget {
  const _MarkAllReadSheetBody({required this.sheetContext});

  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(notificationsViewModelProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyTint35,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Gap.h24,
          SvgPicture.asset(
            SvgAssets.notificationsMarkReadConfirm,
            width: 54.49,
            height: 48,
          ),
          Gap.h16,
          AppText.medium(
            "Mark notifications as read",
            fontSize: 18,
            color: AppColors.black,
            textAlign: TextAlign.center,
          ),
          Gap.h4,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AppText.regular(
              "All unread notifications will be marked as read. Are you sure you want to continue?",
              fontSize: 14,
              color: AppColors.blackTint20,
              textAlign: TextAlign.center,
              multiText: true,
              height: 1.4,
            ),
          ),
          Gap.h32,
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  text: "Yes, mark all",
                  height: 48,
                  radius: 100,
                  isLoading: vm.markAllReadBusy,
                  enabled: !vm.markAllReadBusy,
                  press: () => unawaited(_onConfirm(sheetContext, ref)),
                ),
              ),
              Gap.w12,
              Expanded(
                child: AppButton.onBorder(
                  text: "No, cancel",
                  height: 48,
                  radius: 100,
                  enabled: !vm.markAllReadBusy,
                  press: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm(BuildContext sheetContext, WidgetRef ref) async {
    final ok = await ref.read(notificationsViewModelProvider).markAllAsRead();
    if (!sheetContext.mounted || !ok) return;
    Navigator.of(sheetContext).pop();
  }
}
