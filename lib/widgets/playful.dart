import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wraps a child so it springs down slightly while pressed — gives every
/// tappable surface a satisfying, bouncy feel.
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius? borderRadius;
  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.94,
    this.borderRadius,
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Plays a short pop-in (fade + scale + slide-up) when first built. Stagger a
/// list by passing an increasing [delay].
class PopIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A gently pulsing, glowing flame — used for the streak counter.
class StreakFlame extends StatefulWidget {
  final double size;
  const StreakFlame({super.key, this.size = 22});

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.scale(
          scale: 0.92 + 0.16 * t,
          child: Icon(
            Icons.local_fire_department,
            color: Color.lerp(AppTheme.streak, AppTheme.gold, t),
            size: widget.size,
          ),
        );
      },
    );
  }
}

/// A linear progress bar that animates to its value with a rounded, chunky
/// look and an optional gradient fill.
class AnimatedBar extends StatelessWidget {
  final double value;
  final double height;
  final Color background;
  final List<Color>? gradient;
  final Color? color;
  const AnimatedBar({
    super.key,
    required this.value,
    this.height = 12,
    required this.background,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: background),
          LayoutBuilder(
            builder: (context, c) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Container(
                height: height,
                width: c.maxWidth * v,
                decoration: BoxDecoration(
                  color: gradient == null ? (color ?? Colors.white) : null,
                  gradient: gradient == null
                      ? null
                      : LinearGradient(colors: gradient!),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fires a burst of confetti over the whole screen. Insert once high in the
/// tree (e.g. around a Scaffold body) via [ConfettiController].
class ConfettiOverlay extends StatefulWidget {
  final ConfettiController controller;
  final Widget child;
  const ConfettiOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

/// Tiny controller that lets any widget trigger the confetti burst.
class ConfettiController extends ChangeNotifier {
  int _tick = 0;
  int get tick => _tick;
  void play() {
    _tick++;
    notifyListeners();
  }
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  List<_Confetto> _pieces = const [];
  int _lastTick = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  void _onTick() {
    if (widget.controller.tick == _lastTick) return;
    _lastTick = widget.controller.tick;
    final rnd = math.Random();
    _pieces = List.generate(80, (_) => _Confetto.random(rnd));
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_c.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(_pieces, _c.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Confetto {
  final double x; // 0..1 horizontal start
  final double angle;
  final double velocity;
  final double rotation;
  final double size;
  final Color color;
  _Confetto({
    required this.x,
    required this.angle,
    required this.velocity,
    required this.rotation,
    required this.size,
    required this.color,
  });

  factory _Confetto.random(math.Random r) => _Confetto(
        x: r.nextDouble(),
        angle: (r.nextDouble() - 0.5) * 0.6,
        velocity: 0.7 + r.nextDouble() * 0.6,
        rotation: r.nextDouble() * math.pi * 2,
        size: 7 + r.nextDouble() * 8,
        color: AppTheme.palette[r.nextInt(AppTheme.palette.length)],
      );
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetto> pieces;
  final double t; // 0..1
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final dx = size.width * p.x + math.sin(p.angle * 6 + t * 8) * 28;
      final dy = -40 + (size.height + 80) * (t * p.velocity);
      final rot = p.rotation + t * 12;
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
