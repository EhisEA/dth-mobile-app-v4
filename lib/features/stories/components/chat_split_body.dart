import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/stories/components/chat_panel.dart";
import "package:dth_v4/features/stories/components/reel_player_controller.dart";
import "package:dth_v4/features/tickets/tickets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

/// Reel + chat with an explicit split height. Scrolling the chat list at the
/// top grows the sheet (shrinks the reel) until [maxSheetFraction]; dragging
/// on the reel or grab strip does the same. Uses [ScrollPhysics] so list
/// scroll deltas resize the split instead of getting stuck on the video.
class ChatSplitBody extends StatefulWidget {
  const ChatSplitBody({
    super.key,
    required this.reelUid,
    required this.backdrop,
    required this.topPad,
    required this.bottomPad,
    required this.composerController,
    required this.onBack,
    required this.onCloseChat,
    this.playerController,
    this.initialSheetFraction = 0.3,
    this.maxSheetFraction = 0.5,
  });

  final String reelUid;

  /// Pre-built reel backdrop from the parent. Passed in (rather than built
  /// internally) so the same widget instance — and its `State` / underlying
  /// players — survives the chat open/close flip via [StoriesView]'s
  /// [GlobalKey]. Building a fresh [ReelBackdropMedia] here would restart
  /// playback every time the sheet appears.
  final Widget backdrop;

  final double topPad;
  final double bottomPad;
  final TextEditingController composerController;
  final VoidCallback onBack;

  /// Called after a deliberate swipe-down dismiss (animated sheet off-screen).
  final VoidCallback onCloseChat;
  final ReelPlayerController? playerController;
  final double initialSheetFraction;
  final double maxSheetFraction;

  @override
  State<ChatSplitBody> createState() => _ChatSplitBodyState();
}

class _ChatSplitBodyState extends State<ChatSplitBody>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<double> _extentN;
  final ScrollController _listScroll = ScrollController();
  _LinkedSheetScrollPhysics? _linkedPhysics;
  double? _physicsViewportH;
  late final AnimationController _settleCtrl;
  VoidCallback? _settleTick;

  /// Pulls below min shrink the sheet at this fraction of the drag distance,
  /// so the sheet visibly resists — gives the user a "rubber-band" feel
  /// instead of pinning at min while their finger keeps moving.
  static const double _pullDamping = 0.5;

  /// When the user releases below min × this ratio, commit dismiss.
  /// Above it, spring back to min.
  static const double _dismissExtentRatio = 0.6;

  /// Downward fling threshold (logical px/s) that commits dismiss even when
  /// the user hasn't pulled far enough — feels natural for a quick flick.
  static const double _dismissVelocity = 900;

  @override
  void initState() {
    super.initState();
    final minS = widget.initialSheetFraction.clamp(0.05, 0.95);
    _extentN = ValueNotifier(minS);
    _settleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  void _ensureLinkedPhysics() {
    if (_linkedPhysics != null) return;
    final h = _physicsViewportH ?? MediaQuery.sizeOf(context).height;
    _physicsViewportH = h;
    final minS = widget.initialSheetFraction.clamp(0.05, 0.95);
    final maxS = widget.maxSheetFraction.clamp(minS + 0.01, 0.95);
    _linkedPhysics = _LinkedSheetScrollPhysics(
      parent: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      viewportHeight: h,
      minSheet: minS,
      maxSheet: maxS,
      // Physics sees the clamped value so its "at min?" check stays correct
      // while we let `_extentN` itself wander below min for the rubber-band.
      extent: () {
        final a = widget.initialSheetFraction.clamp(0.05, 0.95);
        final b = widget.maxSheetFraction.clamp(a + 0.01, 0.95);
        return _extentN.value.clamp(a, b);
      },
      onExtentDeltaFromScrollPixels: (signedPixels) {
        if (_settleCtrl.isAnimating) return;
        final a = widget.initialSheetFraction.clamp(0.05, 0.95);
        final b = widget.maxSheetFraction.clamp(a + 0.01, 0.95);
        final hh = _physicsViewportH ?? h;
        final next = (_extentN.value + signedPixels / hh).clamp(a, b);
        if (next != _extentN.value) _extentN.value = next;
      },
      onDragPastMinAtTop: (px) => _applyOverpullPx(px, _physicsViewportH ?? h),
    );
  }

  @override
  void didUpdateWidget(covariant ChatSplitBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSheetFraction != widget.initialSheetFraction ||
        oldWidget.maxSheetFraction != widget.maxSheetFraction) {
      _linkedPhysics = null;
      _physicsViewportH = null;
    }
  }

  @override
  void dispose() {
    if (_settleTick != null) {
      _settleCtrl.removeListener(_settleTick!);
    }
    _settleCtrl.dispose();
    _extentN.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  /// Drag handler for the reel area + grab strip. Rubber-bands the sheet
  /// below min when the user keeps pulling past it.
  void _applyVerticalDragDy(double dy, double viewportH) {
    if (_settleCtrl.isAnimating) return;
    final minS = widget.initialSheetFraction.clamp(0.05, 0.95);
    final maxS = widget.maxSheetFraction.clamp(minS + 0.01, 0.95);
    final before = _extentN.value;
    final d = -dy / viewportH;
    final candidate = before + d;

    if (candidate >= minS) {
      // Inside the regular [min..max] range — direct, 1:1 tracking.
      _extentN.value = candidate.clamp(minS, maxS);
    } else {
      // Below min: damp the further shrink so the sheet visibly resists.
      final overpullFromMin = (minS - candidate) * _pullDamping;
      _extentN.value = (minS - overpullFromMin).clamp(0.0, minS);
    }
  }

  /// Same idea as [_applyVerticalDragDy] but for the scroll-physics
  /// pull-past-min path — the list reports `downwardPixels` instead of a
  /// signed dy.
  void _applyOverpullPx(double downwardPixels, double viewportH) {
    if (downwardPixels <= 0 || _settleCtrl.isAnimating) return;
    final minS = widget.initialSheetFraction.clamp(0.05, 0.95);
    final from = _extentN.value <= minS ? _extentN.value : minS;
    final next = from - (downwardPixels * _pullDamping) / viewportH;
    _extentN.value = next.clamp(0.0, minS);
  }

  void _onVerticalDragEnd(DragEndDetails details, double viewportH) {
    _settle(primaryVelocity: details.primaryVelocity);
  }

  /// Called from the gesture detector's drag-end AND from the chat list's
  /// scroll-end notification. Decides whether to spring back to min or to
  /// commit dismiss.
  void _settle({double? primaryVelocity}) {
    if (!mounted || _settleCtrl.isAnimating) return;
    final minS = widget.initialSheetFraction.clamp(0.05, 0.95);
    final extent = _extentN.value;
    if (extent >= minS) return; // Above min: ScrollPhysics handles it.

    final dismissByPosition = extent < minS * _dismissExtentRatio;
    final v = primaryVelocity ?? 0;
    final dismissByVelocity = v > _dismissVelocity;

    if (dismissByPosition || dismissByVelocity) {
      _animateExtentTo(0, dismiss: true);
    } else {
      _animateExtentTo(minS, dismiss: false);
    }
  }

  /// Drives `_extentN` from its current value to [target] over a short
  /// curve. When [dismiss] is true, calls [ChatSplitBody.onCloseChat] on
  /// completion; otherwise just lands at [target] (used for spring-back).
  void _animateExtentTo(double target, {required bool dismiss}) {
    if (!mounted || _settleCtrl.isAnimating) return;
    final start = _extentN.value;
    if ((start - target).abs() < 0.001) {
      if (dismiss) widget.onCloseChat();
      return;
    }
    _settleCtrl.reset();
    _settleCtrl.duration = Duration(milliseconds: dismiss ? 280 : 220);
    final curved = CurvedAnimation(
      parent: _settleCtrl,
      curve: dismiss ? Curves.easeInCubic : Curves.easeOutCubic,
    );
    void tick() {
      if (!mounted) return;
      _extentN.value = start + (target - start) * curved.value;
    }

    _settleTick = tick;
    _settleCtrl.addListener(tick);
    _settleCtrl.forward().whenComplete(() {
      if (_settleTick != null) {
        _settleCtrl.removeListener(_settleTick!);
        _settleTick = null;
      }
      curved.dispose();
      if (mounted && dismiss) widget.onCloseChat();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the constraint height (LayoutBuilder) instead of screen height so
    // the split tracks Scaffold's keyboard-resize. Without this, opening the
    // keyboard while the chat sheet is up leaves the composer behind the
    // keyboard — the split math is computed against full screen but the
    // available body has already been shrunk.
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        if (_physicsViewportH != h) {
          _physicsViewportH = h;
          _linkedPhysics = null;
        }
        _ensureLinkedPhysics();
        final physics = _linkedPhysics!;
        return _buildSplit(context, h, physics);
      },
    );
  }

  Widget _buildSplit(BuildContext context, double h, ScrollPhysics physics) {
    return ListenableBuilder(
      listenable: _extentN,
      builder: (context, _) {
        final minS = widget.initialSheetFraction.clamp(0.05, 0.95);
        final maxS = widget.maxSheetFraction.clamp(minS + 0.01, 0.95);
        // Allow extent to dip below `minS` for the rubber-band pull — the
        // sheet shrinks visually as the user keeps dragging past min.
        final extent = _extentN.value.clamp(0.0, maxS);
        final reelH = h * (1 - extent);
        final sheetH = h * extent;

        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: reelH,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (d) =>
                      _applyVerticalDragDy(d.primaryDelta ?? 0, h),
                  onVerticalDragEnd: (d) => _onVerticalDragEnd(d, h),
                  onVerticalDragCancel: () => _settle(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.backdrop,
                      const ColoredBox(color: Color(0x22000000)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: reelH,
                height: sheetH,
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: (d) =>
                            _applyVerticalDragDy(d.primaryDelta ?? 0, h),
                        onVerticalDragEnd: (d) => _onVerticalDragEnd(d, h),
                        onVerticalDragCancel: () => _settle(),
                        child: SizedBox(
                          height: 28,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: _SheetProgressBar(
                                controller: widget.playerController,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n is ScrollEndNotification) {
                              _settle(
                                primaryVelocity:
                                    n.dragDetails?.primaryVelocity,
                              );
                            }
                            return false;
                          },
                          child: ChatPanel(
                            reelUid: widget.reelUid,
                            scrollController: _listScroll,
                            scrollPhysics: physics,
                            bottomPad: widget.bottomPad,
                            composerController: widget.composerController,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: widget.topPad + 8,
                left: 12,
                child: CircleBlurIconButton(
                  onTap: widget.onBack,
                  child: SvgPicture.asset(
                    SvgAssets.backArrow,
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Routes vertical scroll into sheet extent while the list is pinned at the
/// top (grow sheet on drag-up) or has room to shrink the sheet (drag-down).
///
/// [ScrollPosition.applyUserOffset]: `setPixels(pixels - physics(..., delta))`.
class _LinkedSheetScrollPhysics extends ScrollPhysics {
  // ignore: prefer_const_constructors_in_immutables — closures + non-const parent.
  _LinkedSheetScrollPhysics({
    required super.parent,
    required this.viewportHeight,
    required this.minSheet,
    required this.maxSheet,
    required this.extent,
    required this.onExtentDeltaFromScrollPixels,
    required this.onDragPastMinAtTop,
  });

  final double viewportHeight;
  final double minSheet;
  final double maxSheet;
  final double Function() extent;

  /// Added to sheet extent: `pixels / viewportHeight` (positive grows sheet).
  final void Function(double signedPixels) onExtentDeltaFromScrollPixels;

  /// Downward scroll delta (px) when the sheet is already at [minSheet].
  final void Function(double downwardPixels) onDragPastMinAtTop;

  @override
  _LinkedSheetScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _LinkedSheetScrollPhysics(
      parent: parent!.applyTo(ancestor),
      viewportHeight: viewportHeight,
      minSheet: minSheet,
      maxSheet: maxSheet,
      extent: extent,
      onExtentDeltaFromScrollPixels: onExtentDeltaFromScrollPixels,
      onDragPastMinAtTop: onDragPastMinAtTop,
    );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    final e = extent();
    if (e < maxSheet || e > minSheet) return true;
    return parent!.shouldAcceptUserOffset(position);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    final e = extent();
    final atTop = position.pixels <= position.minScrollExtent + 1.0;

    if (atTop) {
      // Drag up (negative delta) → grow sheet until max.
      if (offset < 0) {
        final avail = -offset;
        final roomPx = (maxSheet - e) * viewportHeight;
        if (roomPx > 1e-3) {
          final intoSheet = avail < roomPx ? avail : roomPx;
          onExtentDeltaFromScrollPixels(intoSheet);
          final remainder = offset + intoSheet;
          if (remainder.abs() < 1e-6) {
            return 0;
          }
          return parent!.applyPhysicsToUserOffset(position, remainder);
        }
      }
      // Drag down (positive delta) → shrink sheet until min.
      else if (offset > 0) {
        final avail = offset;
        final roomPx = (e - minSheet) * viewportHeight;
        if (roomPx > 1e-3) {
          final intoSheet = avail < roomPx ? avail : roomPx;
          onExtentDeltaFromScrollPixels(-intoSheet);
          final remainder = offset - intoSheet;
          if (remainder.abs() < 1e-6) {
            return 0;
          }
          final eAfter = extent();
          if (eAfter <= minSheet + 1e-5) {
            onDragPastMinAtTop(remainder);
            return 0;
          }
          return parent!.applyPhysicsToUserOffset(position, remainder);
        } else {
          onDragPastMinAtTop(avail);
          return 0;
        }
      }
    }

    return parent!.applyPhysicsToUserOffset(position, offset);
  }
}

/// Mini playback progress strip shown above the chat sheet's grab handle.
/// Listens to the same [ReelPlayerController] that the reel backdrop drives,
/// so it ticks in lockstep with the video. Falls back to an empty bar when no
/// controller is attached (image-only reels).
class _SheetProgressBar extends StatelessWidget {
  const _SheetProgressBar({required this.controller});

  final ReelPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) {
      return _bar(0);
    }
    return AnimatedBuilder(
      animation: c,
      builder: (_, _) => _bar(c.progress),
    );
  }

  Widget _bar(double progress) {
    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      minHeight: 4,
      backgroundColor: AppColors.white,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
    );
  }
}
