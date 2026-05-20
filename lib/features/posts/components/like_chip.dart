import "dart:math" as math;

import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Like chip with a celebratory animation when the like flips on: heart
/// pop-bounce, color cross-fade grey → red, mini-heart burst, count tween,
/// and a haptic thump.
class LikeChip extends StatefulWidget {
  const LikeChip({
    super.key,
    required this.liked,
    required this.count,
    this.padding,
    this.onTap,
    this.iconSize = 14,
    this.fontSize = 12,
    this.inactiveColor,
    this.countColor,
    this.countLabel,
  });

  final EdgeInsets? padding;
  final bool liked;
  final int count;
  final VoidCallback? onTap;
  final double iconSize;
  final double fontSize;

  /// Heart color when [liked] is false. Defaults to [AppColors.blackTint20].
  final Color? inactiveColor;

  /// Count text color. Defaults to [AppColors.tint25].
  final Color? countColor;

  /// Pre-formatted count override (e.g. `"16k"`). When set, replaces the
  /// numeric tween display.
  final String? countLabel;

  @override
  State<LikeChip> createState() => _LikeChipState();
}

class _LikeChipState extends State<LikeChip> with TickerProviderStateMixin {
  static const Color _activeColor = Color(0xffE74C3C);

  late final AnimationController _pop;
  late final Animation<double> _popScale;
  late final AnimationController _burst;
  late final AnimationController _colorTween;

  final math.Random _random = math.Random();
  List<_BurstParticle> _particles = const [];

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.55,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.55,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_pop);

    _burst =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 850),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _particles = const []);
          }
        });

    _colorTween = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.liked ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant LikeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liked != widget.liked) {
      if (widget.liked) {
        _colorTween.forward();
        _celebrate();
      } else {
        _colorTween.reverse();
      }
    }
  }

  void _celebrate() {
    HapticFeedback.lightImpact();
    _pop.forward(from: 0);
    setState(() {
      _particles = List.generate(7, (_) {
        // Aim mostly up, within a wide cone.
        final angle =
            -math.pi / 2 + (_random.nextDouble() - 0.5) * (math.pi * 0.9);
        // Particle reach scales with the icon size so smaller chips have
        // tighter bursts.
        return _BurstParticle(
          angle: angle,
          distance:
              widget.iconSize * 2 +
              _random.nextDouble() * widget.iconSize * 1.6,
          size:
              widget.iconSize * 0.5 +
              _random.nextDouble() * widget.iconSize * 0.5,
          delay: _random.nextDouble() * 0.18,
        );
      });
    });
    _burst.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    _burst.dispose();
    _colorTween.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.iconSize;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: widget.padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: s,
              height: s,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  for (final p in _particles)
                    _BurstParticleWidget(
                      particle: p,
                      controller: _burst,
                      color: _activeColor,
                      origin: s / 2,
                    ),
                  ScaleTransition(
                    scale: _popScale,
                    child: AnimatedBuilder(
                      animation: _colorTween,
                      builder: (_, _) {
                        final t = _colorTween.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: 1 - t,
                              child: SvgPicture.asset(
                                SvgAssets.favoriteBorder,
                                height: s,
                                width: s,
                                colorFilter: ColorFilter.mode(
                                  widget.inactiveColor ?? AppColors.blackTint20,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: t,
                              child: SvgPicture.asset(
                                SvgAssets.favorite,
                                height: s,
                                width: s,
                                colorFilter: const ColorFilter.mode(
                                  _activeColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (widget.count > 0) ...[
              Gap.w4,
              AppText.medium(
                widget.countLabel ?? formatCount(widget.count),
                fontSize: widget.fontSize,
                color: widget.countColor ?? AppColors.tint25,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@immutable
class _BurstParticle {
  const _BurstParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });

  final double angle;
  final double distance;
  final double size;
  final double delay;
}

class _BurstParticleWidget extends StatelessWidget {
  const _BurstParticleWidget({
    required this.particle,
    required this.controller,
    required this.color,
    required this.origin,
  });

  final _BurstParticle particle;
  final AnimationController controller;
  final Color color;
  final double origin;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final raw = (controller.value - particle.delay) / (1 - particle.delay);
        if (raw <= 0) return const SizedBox.shrink();
        final t = raw.clamp(0.0, 1.0);
        final eased = 1 - math.pow(1 - t, 3).toDouble();
        final dx = math.cos(particle.angle) * particle.distance * eased;
        final dy = math.sin(particle.angle) * particle.distance * eased;
        final scale = t < 0.3 ? (t / 0.3) : 1.0;
        final opacity = (1 - t).clamp(0.0, 1.0);
        return Positioned(
          left: origin + dx - particle.size / 2,
          top: origin + dy - particle.size / 2,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Icon(
                Icons.favorite_rounded,
                size: particle.size,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}
