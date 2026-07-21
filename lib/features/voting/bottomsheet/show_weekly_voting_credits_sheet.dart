import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/voting/components/voting_sponsor_footer.dart";
import "package:dth_v4/features/voting/models/voting_credits.dart";
import "package:dth_v4/features/voting/models/voting_tutorial.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showWeeklyVotingCreditsSheet(
  BuildContext context, {
  required VotingCredits credits,
  VotingTutorial? tutorial,
  VoidCallback? onCompleted,
}) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    builder: (sheetContext) => _WeeklyVotingCreditsSheetBody(
      credits: credits,
      tutorial: tutorial,
      onCompleted: onCompleted,
    ),
  );
}

class _WeeklyVotingCreditsSheetBody extends StatefulWidget {
  const _WeeklyVotingCreditsSheetBody({
    required this.credits,
    required this.tutorial,
    this.onCompleted,
  });

  final VotingCredits credits;
  final VotingTutorial? tutorial;
  final VoidCallback? onCompleted;

  @override
  State<_WeeklyVotingCreditsSheetBody> createState() =>
      _WeeklyVotingCreditsSheetBodyState();
}

class _WeeklyVotingCreditsSheetBodyState
    extends State<_WeeklyVotingCreditsSheetBody> {
  static const _fallbackTitle = "What are weekly voting credits?";
  static const _fallbackBody =
      "Your weekly voting credits are the number of votes you can cast each week based on your subscription plan.";
  static const _fallbackSection = "How weekly credits work:";
  static const _fallbackCta = "Alright. Got it.";
  static const _fallbackBullets = [
    "Your voting credits refresh automatically every week.",
    "Use as many voting credits as you'd like for each vote.",
    "Upgrade anytime to enjoy more weekly voting credits.",
  ];
  static const _pageAnimDuration = Duration(milliseconds: 280);
  static const _swipeVelocityThreshold = 200.0;

  int _pageIndex = 0;

  VotingTutorial? get _tutorial => widget.tutorial;
  VotingCredits get _credits => widget.credits;

  bool get _hasSteps => _tutorial != null && _tutorial!.steps.isNotEmpty;

  int get _pageCount => _hasSteps ? _tutorial!.steps.length : 1;

  bool get _isLastPage => _pageIndex >= _pageCount - 1;

  String get _ctaLabel {
    if (!_hasSteps) return _fallbackCta;
    if (!_isLastPage) return "Continue";
    final step = _tutorial!.steps[_pageIndex];
    final stepCta = step.ctaLabel.trim();
    if (stepCta.isNotEmpty) return stepCta;
    final rootCta = _tutorial!.ctaLabel.trim();
    if (rootCta.isNotEmpty) return rootCta;
    return _fallbackCta;
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _pageCount || index == _pageIndex) return;
    setState(() => _pageIndex = index);
  }

  void _onCtaPressed() {
    HapticFeedback.lightImpact();
    if (!_isLastPage) {
      _goToPage(_pageIndex + 1);
      return;
    }
    widget.onCompleted?.call();
    Navigator.of(context).maybePop();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_pageCount <= 1) return;
    final vx = details.primaryVelocity ?? 0;
    if (vx <= -_swipeVelocityThreshold) {
      _goToPage(_pageIndex + 1);
    } else if (vx >= _swipeVelocityThreshold) {
      _goToPage(_pageIndex - 1);
    }
  }

  Widget _pageForIndex(int index) {
    if (!_hasSteps) {
      return _FallbackCreditsPage(
        key: const ValueKey("fallback"),
        credits: _credits,
      );
    }
    final step = _tutorial!.steps[index];
    if (index == 0) {
      return _WelcomeTutorialPage(key: ValueKey("welcome-$index"), step: step);
    }
    return _CreditsTutorialPage(
      key: ValueKey("credits-$index"),
      step: step,
      credits: _credits,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  child: AnimatedSize(
                    duration: _pageAnimDuration,
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: _pageAnimDuration,
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.hardEdge,
                          children: [
                            ...previousChildren.map(
                              (child) => Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                child: child,
                              ),
                            ),
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _pageForIndex(_pageIndex),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_pageCount > 1) ...[
                    _PageIndicator(count: _pageCount, index: _pageIndex),
                    Gap.h16,
                  ],
                  AppButton.primary(text: _ctaLabel, press: _onCtaPressed),
                ],
              ),
            ),
            const VotingSponsorFooter(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeTutorialPage extends StatelessWidget {
  const _WelcomeTutorialPage({super.key, required this.step});

  final VotingTutorialStep step;

  @override
  Widget build(BuildContext context) {
    final heading = step.heading.trim().isNotEmpty
        ? step.heading.trim()
        : "Welcome to voting";
    final subtitle = step.subtitle.trim().isNotEmpty
        ? step.subtitle.trim()
        : "Support your favorite contestants and help shape the competition.";
    final section = step.sectionLabel.trim().isNotEmpty
        ? step.sectionLabel.trim()
        : "How it works:";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset(
            ImageAssets.votingTutorialHeader,
            height: 140,
            width: context.width / 1,
            fit: BoxFit.cover,
          ),
        ),
        AppText.semiBold(
          heading,
          fontSize: 24,
          color: AppColors.tertiary60,
          textAlign: TextAlign.center,
          height: 1,
        ),
        Gap.h4,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppText.regular(
            subtitle,
            fontSize: 14,
            height: 1.45,
            color: const Color(0xff454545),
            centered: true,
            textAlign: TextAlign.center,
            multiText: true,
          ),
        ),
        Gap.h24,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AppText.medium(section, fontSize: 14, color: AppColors.black),
        ),
        Gap.h16,
        ...step.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
            child: _IconTutorialRow(item: item),
          ),
        ),
      ],
    );
  }
}

class _CreditsTutorialPage extends StatelessWidget {
  const _CreditsTutorialPage({
    super.key,
    required this.step,
    required this.credits,
  });

  final VotingTutorialStep step;
  final VotingCredits credits;

  @override
  Widget build(BuildContext context) {
    final heading = step.heading.trim().isNotEmpty
        ? step.heading.trim()
        : "What are weekly voting credits?";
    final subtitle = step.subtitle.trim().isNotEmpty
        ? step.subtitle.trim()
        : "Your weekly voting credits are the number of votes you can cast each week based on your subscription plan.";
    final section = step.sectionLabel.trim().isNotEmpty
        ? step.sectionLabel.trim()
        : "How weekly credits work:";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _CreditsBadge(label: credits.label)),
        Gap.h8,
        AppText.medium(
          heading,
          fontSize: 18,
          color: AppColors.mainBlack,
          textAlign: TextAlign.center,
          height: 1,
        ),
        Gap.h8,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppText.regular(
            subtitle,
            fontSize: 16,
            height: 1.45,
            color: const Color(0xff454545),
            centered: true,
            textAlign: TextAlign.center,
            multiText: true,
          ),
        ),
        Gap.h28,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AppText.semiBold(
            section,
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
        Gap.h12,
        ...step.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
            child: _IconTutorialRow(item: item),
          ),
        ),
      ],
    );
  }
}

class _FallbackCreditsPage extends StatelessWidget {
  const _FallbackCreditsPage({super.key, required this.credits});

  final VotingCredits credits;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _CreditsBadge(label: credits.label)),
        Gap.h8,
        AppText.medium(
          _WeeklyVotingCreditsSheetBodyState._fallbackTitle,
          fontSize: 18,
          color: AppColors.mainBlack,
          textAlign: TextAlign.center,
          height: 1,
        ),
        Gap.h8,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppText.regular(
            _WeeklyVotingCreditsSheetBodyState._fallbackBody,
            fontSize: 16,
            height: 1.45,
            color: const Color(0xff454545),
            centered: true,
            textAlign: TextAlign.center,
            multiText: true,
          ),
        ),
        Gap.h28,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AppText.semiBold(
            _WeeklyVotingCreditsSheetBodyState._fallbackSection,
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
        Gap.h12,
        ..._WeeklyVotingCreditsSheetBodyState._fallbackBullets.map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
            child: _BulletRow(text: text),
          ),
        ),
      ],
    );
  }
}

class _IconTutorialRow extends StatelessWidget {
  const _IconTutorialRow({required this.item});

  final VotingTutorialItem item;

  String get _asset {
    switch (item.icon.trim().toLowerCase()) {
      case "check-circle":
        return SvgAssets.voteChoose;
      case "send":
        return SvgAssets.voteCast;
      case "sparkles":
      default:
        return SvgAssets.voteStar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SvgPicture.asset(_asset, width: 24, height: 24),
        ),
        Gap.w16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.semiBold(
                item.title,
                fontSize: 14,
                color: AppColors.black,
              ),
              if (item.body.trim().isNotEmpty) ...[
                Gap.h4,
                AppText.regular(
                  item.body,
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.tint25,
                  multiText: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 4,
          width: 24,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.greyTint35,
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}

class _CreditsBadge extends StatelessWidget {
  const _CreditsBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffE5FBF0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(SvgAssets.voteStar),
          Gap.w6,
          AppText.semiBold(label, fontSize: 12, color: const Color(0xff00AD55)),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SvgPicture.asset(SvgAssets.doubleTick),
        ),
        Gap.w16,
        Expanded(
          child: AppText.regular(
            text,
            fontSize: 16,
            letterSpacing: -0.3,
            height: 1.4,
            color: AppColors.mainBlack,
            multiText: true,
          ),
        ),
      ],
    );
  }
}
