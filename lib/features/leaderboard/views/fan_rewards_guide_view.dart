import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/model.dart";
import "package:dth_v4/features/leaderboard/components/fan_rewards_guide_module.dart";
import "package:dth_v4/features/leaderboard/components/guide_tab_bar.dart";
import "package:dth_v4/features/leaderboard/components/guide_tab_content.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

class FanRewardsGuideView extends StatefulWidget {
  const FanRewardsGuideView({super.key, required this.guide});

  static const String path = NavigatorRoutes.fanRewardsGuide;

  final FanLeaderboardGuide guide;

  @override
  State<FanRewardsGuideView> createState() => _FanRewardsGuideViewState();
}

class _FanRewardsGuideViewState extends State<FanRewardsGuideView> {
  late final PageController _pageController;
  int _pageIndex = 0;
  bool _contentVisible = true;
  bool _isAnimating = false;

  static const _pillBg = Color(0xff1B1B1B);
  static const _pillActive = Color(0xff1B1B1B);
  static const _calloutBg = Color(0xff151515);
  static const _pageAnimDuration = Duration(milliseconds: 300);
  static const _fadeDuration = Duration(milliseconds: 140);
  static const _pageAnimCurve = Curves.easeOutCubic;

  List<FanLeaderboardGuideTab> get _tabs => widget.guide.tabs;

  bool get _isLast => _pageIndex >= _tabs.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int index) async {
    if (index < 0 ||
        index >= _tabs.length ||
        index == _pageIndex ||
        _isAnimating) {
      return;
    }

    final distance = (index - _pageIndex).abs();
    _isAnimating = true;

    if (distance == 1) {
      // Adjacent pages: native side-by-side slide (no stacked text).
      await _pageController.animateToPage(
        index,
        duration: _pageAnimDuration,
        curve: _pageAnimCurve,
      );
    } else {
      // Non-adjacent: fade out → jump → fade in (skips the middle page).
      setState(() => _contentVisible = false);
      await Future<void>.delayed(_fadeDuration);
      if (!mounted) return;
      _pageController.jumpToPage(index);
      setState(() {
        _pageIndex = index;
        _contentVisible = true;
      });
      await Future<void>.delayed(_fadeDuration);
    }

    if (mounted) _isAnimating = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(
              child: AppButton.primary(
                text: "Close",
                press: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      );
    }

    final consentNote = widget.guide.consentNote.trim();
    final ctaLabel = _isLast
        ? (widget.guide.ctaLabel.trim().isEmpty
              ? "Start engaging"
              : widget.guide.ctaLabel)
        : "Next";

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(ImageAssets.leaderboardAddBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Gap.h20,
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: CircleAvatar(
                        radius: 18,
                        foregroundColor: AppColors.white,
                        backgroundColor: _pillBg,
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _contentVisible ? 1 : 0,
                    duration: _fadeDuration,
                    curve: _pageAnimCurve,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _tabs.length,
                      onPageChanged: (index) {
                        setState(() => _pageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final tab = _tabs[index];
                        final module = fanRewardsGuideModuleFor(tab, index);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                          child: GuideTabContent(
                            tab: tab,
                            module: module,
                            calloutBg: _calloutBg,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GuideTabBar(
                    tabs: _tabs,
                    activeIndex: _pageIndex,
                    activeColor: _pillActive,
                    onTap: (i) {
                      HapticFeedback.selectionClick();
                      _goTo(i);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: AppButton.primary(
                    text: ctaLabel,
                    press: () {
                      HapticFeedback.lightImpact();
                      if (_isLast) {
                        Navigator.of(context).pop();
                      } else {
                        _goTo(_pageIndex + 1);
                      }
                    },
                  ),
                ),
                if (consentNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: AnimatedOpacity(
                      opacity: _isLast ? 1 : 0,
                      duration: _pageAnimDuration,
                      child: AppText.regular(
                        consentNote,
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.blackTint20,
                        textAlign: TextAlign.center,
                        multiText: true,
                      ),
                    ),
                  )
                else
                  Gap.h16,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
