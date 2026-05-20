import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

/// Fullscreen, pinch-to-zoom photo viewer with iOS-style swipe-down dismiss.
class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });

  final List<String> urls;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, _, _) =>
            FullscreenImageViewer(urls: urls, initialIndex: initialIndex),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  // Drag-to-dismiss thresholds.
  static const double _dismissDistance = 120;
  static const double _dismissVelocity = 800;
  // How far you have to drag for the backdrop to be fully transparent.
  static const double _fadeRange = 320;

  late final PageController _pageController;
  late int _current;
  // Each page gets its own TransformationController so zoom state is per-image
  // and resets cleanly when the user swipes between pages.
  late final List<TransformationController> _transformControllers;

  // Snap-back animation for when the dismiss gesture is released without
  // crossing the dismiss threshold.
  late final AnimationController _snapBack;
  Animation<double> _snapTween = const AlwaysStoppedAnimation(0);

  double _dragY = 0;
  bool _draggingActive = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageController = PageController(initialPage: _current);
    _transformControllers = List.generate(
      widget.urls.length,
      (_) => TransformationController(),
    );
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() => setState(() => _dragY = _snapTween.value));
  }

  @override
  void dispose() {
    _snapBack.dispose();
    _pageController.dispose();
    for (final c in _transformControllers) {
      c.dispose();
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _onPageChanged(int index) {
    _transformControllers[_current].value = Matrix4.identity();
    setState(() => _current = index);
  }

  double _currentScale() =>
      _transformControllers[_current].value.getMaxScaleOnAxis();

  void _onVerticalDragStart(DragStartDetails details) {
    // Only allow swipe-dismiss when the image is at its base 1x scale —
    // otherwise vertical drags should pan the zoomed image.
    if (_currentScale() > 1.05) return;
    _snapBack.stop();
    _draggingActive = true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_draggingActive) return;
    setState(() => _dragY += details.primaryDelta ?? 0);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_draggingActive) return;
    _draggingActive = false;
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        _dragY > _dismissDistance || velocity > _dismissVelocity;
    if (shouldDismiss) {
      Navigator.of(context).pop();
    } else {
      _snapTween = Tween<double>(
        begin: _dragY,
        end: 0,
      ).animate(CurvedAnimation(parent: _snapBack, curve: Curves.easeOut));
      _snapBack.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.urls.length;
    final fadeProgress = (_dragY.abs() / _fadeRange).clamp(0.0, 1.0);
    final backdropOpacity = 1.0 - fadeProgress;
    final controlsOpacity = 1.0 - fadeProgress;
    // Photo shrinks as it's pulled — 1.0 at rest, ~0.75 at full drag.
    final dragScale = 1.0 - fadeProgress * 0.25;
    // Photo itself fades along with the drag so it dissolves rather than
    // just sliding off-screen.
    final photoOpacity = 1.0 - fadeProgress * 0.6;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: backdropOpacity),
              ),
            ),
            Opacity(
              opacity: photoOpacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, _dragY),
                child: Transform.scale(
                  scale: dragScale,
                  child: GestureDetector(
                    onVerticalDragStart: _onVerticalDragStart,
                    onVerticalDragUpdate: _onVerticalDragUpdate,
                    onVerticalDragEnd: _onVerticalDragEnd,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: n,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (_, i) => InteractiveViewer(
                        transformationController: _transformControllers[i],
                        minScale: 1,
                        maxScale: 4,
                        clipBehavior: Clip.none,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: widget.urls[i],
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                            errorWidget: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Controls fade as the user drags so they don't fight the dismiss
            // visually.
            IgnorePointer(
              ignoring: controlsOpacity < 0.05,
              child: Opacity(
                opacity: controlsOpacity.clamp(0.0, 1.0),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _GlassIconButton(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        if (n > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: AppText.medium(
                              "${_current + 1} / $n",
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: const Color(0xFF101010).withValues(alpha: 0.4),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
