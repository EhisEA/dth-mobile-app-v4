import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/bottomsheet/show_top_up_voting_credits_sheet.dart";
import "package:dth_v4/features/voting/models/voting_running_low_prompt.dart";
import "package:dth_v4/features/voting/view_model/voting_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Shows the running-low popup once per voting week (per app session) when
/// the latest `/voting/week` response has `voting_credit_info.running_low`.
/// Skips when another route (sheet, tutorial, page) is on top of [context].
Future<void> maybeShowRunningLowVotingCreditsSheet(
  BuildContext context,
  VotingViewModel vm,
) async {
  if (!context.mounted || !vm.shouldPromptRunningLow) return;
  final prompt = vm.creditInfo.runningLow;
  if (prompt == null) return;
  if (!_isTopmost(context)) return;
  vm.markRunningLowPrompted();
  await showRunningLowVotingCreditsSheet(context, prompt: prompt);
}

/// True only when nothing is stacked above [context] in *any* navigator.
/// The voting tab lives in a nested (bottom-nav) navigator while sheets such
/// as vote / vote-success / top-up open on the root navigator, so checking
/// only the nearest route would miss them — walk up through every navigator.
bool _isTopmost(BuildContext context) {
  if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
  // Note: `Navigator.maybeOf(nav.context)` returns `nav` itself (Flutter
  // checks the context's own state first), so step to the *ancestor*
  // navigator explicitly — otherwise this never reaches the root.
  var nav = context.findAncestorStateOfType<NavigatorState>();
  while (nav != null) {
    final parent = nav.context.findAncestorStateOfType<NavigatorState>();
    if (parent == null) return true;
    // The route in [parent] that hosts the nested [nav].
    final hostRoute = ModalRoute.of(nav.context);
    if (hostRoute != null && !hostRoute.isCurrent) return false;
    nav = parent;
  }
  return true;
}

/// Centered popup shown when `/voting/week` reports
/// `voting_credit_info.running_low`. All copy comes from [prompt]; the CTA
/// closes the popup and opens the top-up voting credits sheet.
Future<void> showRunningLowVotingCreditsSheet(
  BuildContext context, {
  required VotingRunningLowPrompt prompt,
}) async {
  final topUp = await showBlurredModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isCentered: true,
    enableDrag: false,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (sheetContext) =>
        _RunningLowVotingCreditsSheetBody(prompt: prompt),
  );
  if (topUp == true && context.mounted) {
    unawaited(showTopUpVotingCreditsSheet(context));
  }
}

class _RunningLowVotingCreditsSheetBody extends StatelessWidget {
  const _RunningLowVotingCreditsSheetBody({required this.prompt});

  final VotingRunningLowPrompt prompt;

  static final _tagRe = RegExp(
    r"<\s*/?\s*(em|b|u|i)\s*>",
    caseSensitive: false,
  );

  /// Title and button render as plain text — drop any inline tags.
  static String _stripTags(String text) => text.replaceAll(_tagRe, "");

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _RunningLowIllustration(),
              Gap.h24,
              const _DashedDivider(),
              Gap.h32,
              AppText.medium(
                _stripTags(prompt.title),
                fontSize: 18,
                color: AppColors.black,
                textAlign: TextAlign.center,
                multiText: true,
              ),
              Gap.h16,
              // `<b>` / `<u>` / `<i>` in the backend message style that span.
              InlineTaggedText(
                prompt.message,
                fontSize: 14,
                height: 1.4,
                color: const Color(0xff454545),
                strongColor: AppColors.black,
                maxLines: 6,
                textAlign: TextAlign.center,
              ),
              Gap.h24,
              AppButton.primary(
                text: _stripTags(prompt.ctaLabel),
                press: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
        ),
        Gap.h16,
        Material(
          color: AppColors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop();
            },
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.close, size: 18, color: Color(0xff505050)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill with a star badge, placeholder bars and a "Running Low" chip —
/// mirrors the "Access Denied" header of the subscription popup.
class _RunningLowIllustration extends StatelessWidget {
  const _RunningLowIllustration();

  static const _warning = Color(0xffE5484D);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xffF1F3F6), width: 6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff8FA3C8).withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffEAF8F1),
                border: Border.all(color: const Color(0xffBFEBD4), width: 3),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(SvgAssets.voteStar, width: 16),
            ),
            Gap.w8,
            for (var i = 0; i < 3; i++) ...[
              Container(
                width: 16,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F6F9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Gap.w4,
            ],
            Gap.w4,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xffFFF5F5),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xffFFE0E0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_down_rounded,
                    size: 14,
                    color: _warning,
                  ),
                  Gap.w4,
                  AppText.semiBold(
                    "Running Low",
                    fontSize: 12,
                    color: _warning,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 6.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dash,
              height: 1,
              color: const Color(0xffE4E7EC),
            ),
          ),
        );
      },
    );
  }
}
