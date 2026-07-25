import "dart:math" as math;

import "package:confetti/confetti.dart";
import "package:flutter/material.dart";

/// Full-screen confetti burst used after celebratory actions (poll vote, etc.).
class TopConfettiCelebration extends StatefulWidget {
  const TopConfettiCelebration({
    super.key,
    this.onFinished,
    this.confinedToContainer = false,
  });

  /// Called after particles finish; useful when shown in an [OverlayEntry].
  final VoidCallback? onFinished;

  /// When true, emitters anchor to the top edge of the parent bounds (e.g. a
  /// bottom sheet) instead of the full screen.
  final bool confinedToContainer;

  static const Duration duration = Duration(milliseconds: 2200);
  static const Duration cleanup = Duration(milliseconds: 5500);

  static const List<Color> colors = [
    Color(0xFF00AD55),
    Color(0xFF284FEB),
    Color(0xFFF2A257),
    Color(0xFFFE5349),
    Color(0xFFFFD700),
    Color(0xFFE94B92),
    Color(0xFF7C4DFF),
  ];

  static const Size minSize = Size(8, 4);
  static const Size maxSize = Size(18, 10);

  @override
  State<TopConfettiCelebration> createState() => _TopConfettiCelebrationState();
}

class _TopConfettiCelebrationState extends State<TopConfettiCelebration> {
  late final ConfettiController _centerController;
  late final ConfettiController _leftController;
  late final ConfettiController _rightController;

  @override
  void initState() {
    super.initState();
    _centerController = ConfettiController(
      duration: TopConfettiCelebration.duration,
    );
    _leftController = ConfettiController(
      duration: TopConfettiCelebration.duration,
    );
    _rightController = ConfettiController(
      duration: TopConfettiCelebration.duration,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerController.play();
      _leftController.play();
      _rightController.play();
      final onFinished = widget.onFinished;
      if (onFinished != null) {
        Future.delayed(TopConfettiCelebration.cleanup, onFinished);
      }
    });
  }

  @override
  void dispose() {
    _centerController.dispose();
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confined = widget.confinedToContainer;
    final centerAlignment = confined
        ? Alignment.topCenter
        : const Alignment(0, -0.7);
    final leftAlignment = confined
        ? const Alignment(-0.95, -1)
        : const Alignment(-0.9, -0.95);
    final rightAlignment = confined
        ? const Alignment(0.95, -1)
        : const Alignment(0.9, -0.95);
    final centerParticles = confined ? 28 : 45;
    final sideParticles = confined ? 18 : 30;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: centerAlignment,
            child: ConfettiWidget(
              confettiController: _centerController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: confined ? 0.06 : 0.08,
              numberOfParticles: centerParticles,
              minBlastForce: confined ? 18 : 25,
              maxBlastForce: confined ? 40 : 55,
              gravity: 0.35,
              particleDrag: 0.04,
              shouldLoop: false,
              colors: TopConfettiCelebration.colors,
              minimumSize: TopConfettiCelebration.minSize,
              maximumSize: TopConfettiCelebration.maxSize,
            ),
          ),
          Align(
            alignment: leftAlignment,
            child: ConfettiWidget(
              confettiController: _leftController,
              blastDirection: math.pi / 3,
              blastDirectionality: BlastDirectionality.directional,
              emissionFrequency: confined ? 0.08 : 0.1,
              numberOfParticles: sideParticles,
              minBlastForce: confined ? 22 : 30,
              maxBlastForce: confined ? 40 : 55,
              gravity: 0.35,
              particleDrag: 0.04,
              shouldLoop: false,
              colors: TopConfettiCelebration.colors,
              minimumSize: TopConfettiCelebration.minSize,
              maximumSize: TopConfettiCelebration.maxSize,
            ),
          ),
          Align(
            alignment: rightAlignment,
            child: ConfettiWidget(
              confettiController: _rightController,
              blastDirection: 2 * math.pi / 3,
              blastDirectionality: BlastDirectionality.directional,
              emissionFrequency: confined ? 0.08 : 0.1,
              numberOfParticles: sideParticles,
              minBlastForce: confined ? 22 : 30,
              maxBlastForce: confined ? 40 : 55,
              gravity: 0.35,
              particleDrag: 0.04,
              shouldLoop: false,
              colors: TopConfettiCelebration.colors,
              minimumSize: TopConfettiCelebration.minSize,
              maximumSize: TopConfettiCelebration.maxSize,
            ),
          ),
        ],
      ),
    );
  }
}
