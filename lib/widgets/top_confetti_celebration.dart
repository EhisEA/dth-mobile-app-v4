import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";

/// Full-screen confetti celebration used after celebratory actions (poll vote,
/// contestant vote, etc.).
///
/// Two side cannons fire paper up and inward while a light shower falls from
/// the top. Each piece decelerates under air drag, then flutters down at a
/// gentle terminal speed — swaying, spinning and flipping in 3D — and fades
/// out instead of popping off. [onFinished] fires once every piece is gone.
class TopConfettiCelebration extends StatefulWidget {
  const TopConfettiCelebration({
    super.key,
    this.onFinished,
    this.confinedToContainer = false,
  });

  /// Called after particles finish; useful when shown in an [OverlayEntry].
  final VoidCallback? onFinished;

  /// When true, emitters anchor to the top corners of the parent bounds (e.g.
  /// a bottom sheet) and fewer pieces are fired.
  final bool confinedToContainer;

  static const List<Color> colors = [
    Color(0xFF00AD55),
    Color(0xFF284FEB),
    Color(0xFFF2A257),
    Color(0xFFFE5349),
    Color(0xFFFFD700),
    Color(0xFFE94B92),
    Color(0xFF7C4DFF),
  ];

  @override
  State<TopConfettiCelebration> createState() => _TopConfettiCelebrationState();
}

class _TopConfettiCelebrationState extends State<TopConfettiCelebration>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  final _frame = ValueNotifier<int>(0);
  final List<_Piece> _pieces = [];
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Size? _size;
  bool _spawned = false;
  bool _finished = false;

  /// Downward acceleration (logical px/s²). With each piece's drag this gives
  /// a terminal fall speed of roughly 170–270 px/s — a slow paper flutter.
  static const double _gravity = 700;

  /// Longest frame step simulated at once, so a dropped frame doesn't teleport
  /// pieces across the screen.
  static const double _maxStep = 1 / 30;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the OS "reduce motion" setting: skip the effect entirely.
    if (MediaQuery.of(context).disableAnimations && !_finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  double _rand(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  void _spawn(Size size) {
    _spawned = true;
    final confined = widget.confinedToContainer;
    // Scale launch speeds to the canvas so the burst reaches the same relative
    // height on small and large phones.
    final speedScale = (size.height / 850).clamp(0.6, 1.4);

    final cannonCount = confined ? 30 : 55;
    final cannonY = confined ? 0.0 : size.height * 0.4;
    for (var i = 0; i < cannonCount; i++) {
      for (final fromLeft in const [true, false]) {
        // Up and inward: between 45° and 78° above horizontal.
        final angle = _rand(45, 78) * math.pi / 180;
        final speed = _rand(850, 1500) * speedScale;
        final dx = math.cos(angle) * speed;
        _pieces.add(
          _newPiece(
            position: Offset(fromLeft ? -8 : size.width + 8, cannonY),
            velocity: Offset(fromLeft ? dx : -dx, -math.sin(angle) * speed),
            // Stagger launches so the burst streams out rather than appearing
            // in a single frame.
            delay: _rand(0, 0.28),
          ),
        );
      }
    }

    final showerCount = confined ? 20 : 45;
    for (var i = 0; i < showerCount; i++) {
      _pieces.add(
        _newPiece(
          position: Offset(_rand(0, size.width), _rand(-60, -12)),
          velocity: Offset(_rand(-50, 50), _rand(20, 120)),
          delay: _rand(0.12, 0.9),
        ),
      );
    }
  }

  _Piece _newPiece({
    required Offset position,
    required Offset velocity,
    required double delay,
  }) {
    final roll = _random.nextDouble();
    final _Shape shape;
    final Size size;
    if (roll < 0.55) {
      shape = _Shape.paper;
      size = Size(_rand(6, 9), _rand(9, 13));
    } else if (roll < 0.8) {
      shape = _Shape.strip;
      size = Size(_rand(2.5, 3.5), _rand(13, 18));
    } else {
      shape = _Shape.dot;
      final d = _rand(5.5, 8);
      size = Size(d, d);
    }
    final colors = TopConfettiCelebration.colors;
    return _Piece(
      position: position,
      velocity: velocity,
      color: colors[_random.nextInt(colors.length)],
      shape: shape,
      size: size,
      angle: _rand(0, math.pi * 2),
      spin: _rand(-4, 4),
      flipSpeed: _rand(5, 13),
      flipPhase: _rand(0, math.pi * 2),
      swayAmp: _rand(6, 18),
      swayFreq: _rand(2.5, 5.5),
      swayPhase: _rand(0, math.pi * 2),
      drag: _rand(2.6, 4.2),
      life: _rand(3.4, 4.8),
      age: -delay,
    );
  }

  void _onTick(Duration elapsed) {
    final size = _size;
    if (size == null) return;
    if (!_spawned) _spawn(size);

    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(
      0.0,
      _maxStep,
    );
    _lastTick = elapsed;

    var alive = false;
    for (final p in _pieces) {
      if (p.dead) continue;
      p.age += dt;
      if (p.age < 0) {
        alive = true;
        continue;
      }
      final damping = math.exp(-p.drag * dt);
      p.velocity = Offset(
        p.velocity.dx * damping,
        p.velocity.dy * damping + _gravity * dt,
      );
      p.position += p.velocity * dt;
      p.angle += p.spin * dt;
      if (p.age >= p.life || p.position.dy > size.height + 40) {
        p.dead = true;
      } else {
        alive = true;
      }
    }

    _frame.value++;
    if (!alive) _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    if (_ticker.isActive) _ticker.stop();
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          if (!_ticker.isActive && !_finished) _ticker.start();
          return RepaintBoundary(
            child: CustomPaint(
              size: constraints.biggest,
              painter: _ConfettiPainter(pieces: _pieces, repaint: _frame),
            ),
          );
        },
      ),
    );
  }
}

enum _Shape { paper, strip, dot }

class _Piece {
  _Piece({
    required this.position,
    required this.velocity,
    required this.color,
    required this.shape,
    required this.size,
    required this.angle,
    required this.spin,
    required this.flipSpeed,
    required this.flipPhase,
    required this.swayAmp,
    required this.swayFreq,
    required this.swayPhase,
    required this.drag,
    required this.life,
    required this.age,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final _Shape shape;
  final Size size;
  double angle;
  final double spin;
  final double flipSpeed;
  final double flipPhase;
  final double swayAmp;
  final double swayFreq;
  final double swayPhase;

  /// Air-drag coefficient (1/s). Higher values slow the piece sooner and make
  /// it fall slower.
  final double drag;

  /// Seconds after launch before the piece has fully faded out.
  final double life;

  /// Seconds since launch; negative while waiting for its staggered start.
  double age;
  bool dead = false;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required Listenable repaint})
    : super(repaint: repaint);

  final List<_Piece> pieces;

  static const double _fadeOut = 0.8;
  static const double _fadeIn = 0.08;

  final Paint _paint = Paint()..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      if (p.dead || p.age < 0) continue;

      final opacity = math.min(
        (p.age / _fadeIn).clamp(0.0, 1.0),
        ((p.life - p.age) / _fadeOut).clamp(0.0, 1.0),
      );
      if (opacity <= 0) continue;

      // Sway grows in as the launch speed bleeds off, so pieces shoot out
      // cleanly and only start fluttering once they're drifting.
      final settle = (1 - p.velocity.distance / 450).clamp(0.0, 1.0);
      final sway =
          math.sin(p.age * p.swayFreq + p.swayPhase) * p.swayAmp * settle;

      // 3D tumble: squash one axis by cos(t) and shade the "back" side.
      final flip = math.cos(p.age * p.flipSpeed + p.flipPhase);
      final squash = math.max(flip.abs(), 0.08);
      final base = flip < 0
          ? Color.lerp(p.color, const Color(0xFF000000), 0.22)!
          : p.color;
      _paint.color = base.withValues(alpha: base.a * opacity);

      canvas
        ..save()
        ..translate(p.position.dx + sway, p.position.dy)
        ..rotate(p.angle)
        ..scale(1, squash);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size.width,
        height: p.size.height,
      );
      switch (p.shape) {
        case _Shape.paper:
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
            _paint,
          );
        case _Shape.strip:
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(p.size.width / 2)),
            _paint,
          );
        case _Shape.dot:
          canvas.drawOval(rect, _paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}
