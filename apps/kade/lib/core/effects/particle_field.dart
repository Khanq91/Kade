// Port từ Snipz/particle_field: nền hạt 2D có chiều sâu giả, không dependency.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Trường particle nhẹ; số hạt tự co giãn theo diện tích widget.
class ParticleField extends StatefulWidget {
  const ParticleField({
    super.key,
    this.density = 2,
    this.maxParticles = 140,
    required this.colors,
    this.baseSize = 1.8,
    this.driftAmplitude = 9,
    this.speed = .45,
    this.backgroundColor,
    this.interactive = false,
    this.seed = 7,
    this.animate = true,
    this.child,
  });

  /// Số hạt trên 10.000 logical px².
  final double density;
  final int maxParticles;
  final List<Color> colors;
  final double baseSize;
  final double driftAmplitude;
  final double speed;
  final Color? backgroundColor;
  final bool interactive;
  final int seed;
  final bool animate;
  final Widget? child;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier(0);
  final ValueNotifier<Offset> _touch = ValueNotifier(Offset.zero);
  Offset _touchTarget = Offset.zero;
  double _timeBase = 0;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _spawn(widget.seed, widget.maxParticles);
    _ticker = createTicker(_onTick);
    if (widget.animate) _ticker.start();
  }

  static List<_Particle> _spawn(int seed, int count) {
    final rng = math.Random(seed);
    return List.generate(count, (_) {
      final z = .35 + .65 * rng.nextDouble();
      return _Particle(
        fx: rng.nextDouble(),
        fy: rng.nextDouble(),
        z: z,
        freqX: .3 + .7 * rng.nextDouble(),
        freqY: .3 + .7 * rng.nextDouble(),
        phaseX: rng.nextDouble() * 2 * math.pi,
        phaseY: rng.nextDouble() * 2 * math.pi,
        sizeJitter: rng.nextDouble() * 2 - 1,
        twinklePhase: rng.nextDouble() * 2 * math.pi,
        colorIndex: rng.nextInt(1 << 16),
      );
    });
  }

  void _onTick(Duration elapsed) {
    _time.value = _timeBase + elapsed.inMicroseconds / 1e6;
    if (_touch.value != _touchTarget) {
      final next = Offset.lerp(_touch.value, _touchTarget, .12)!;
      _touch.value = (next - _touchTarget).distanceSquared < .01
          ? _touchTarget
          : next;
    }
  }

  @override
  void didUpdateWidget(ParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seed != oldWidget.seed ||
        widget.maxParticles != oldWidget.maxParticles) {
      _particles = _spawn(widget.seed, widget.maxParticles);
    }
    if (widget.animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.animate && _ticker.isActive) {
      _timeBase = _time.value;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _touch.dispose();
    super.dispose();
  }

  void _onPointer(Offset position, Size size) {
    if (!widget.interactive || size.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    _touchTarget = (position - center) * .06;
    if (!_ticker.isActive) _touch.value = _touchTarget;
  }

  void _onPointerEnd() {
    _touchTarget = Offset.zero;
    if (!_ticker.isActive) _touch.value = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final field = CustomPaint(
      painter: _ParticlePainter(
        time: _time,
        touch: _touch,
        particles: _particles,
        density: widget.density,
        colors: widget.colors,
        baseSize: widget.baseSize,
        driftAmplitude: widget.driftAmplitude,
        speed: widget.speed,
        backgroundColor: widget.backgroundColor,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
    if (!widget.interactive) return field;
    return LayoutBuilder(
      builder: (context, constraints) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _onPointer(e.localPosition, constraints.biggest),
        onPointerMove: (e) => _onPointer(e.localPosition, constraints.biggest),
        onPointerUp: (_) => _onPointerEnd(),
        onPointerCancel: (_) => _onPointerEnd(),
        child: field,
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.fx,
    required this.fy,
    required this.z,
    required this.freqX,
    required this.freqY,
    required this.phaseX,
    required this.phaseY,
    required this.sizeJitter,
    required this.twinklePhase,
    required this.colorIndex,
  });

  final double fx;
  final double fy;
  final double z;
  final double freqX;
  final double freqY;
  final double phaseX;
  final double phaseY;
  final double sizeJitter;
  final double twinklePhase;
  final int colorIndex;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.time,
    required this.touch,
    required this.particles,
    required this.density,
    required this.colors,
    required this.baseSize,
    required this.driftAmplitude,
    required this.speed,
    required this.backgroundColor,
  }) : super(repaint: Listenable.merge([time, touch]));

  final ValueListenable<double> time;
  final ValueListenable<Offset> touch;
  final List<_Particle> particles;
  final double density;
  final List<Color> colors;
  final double baseSize;
  final double driftAmplitude;
  final double speed;
  final Color? backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || colors.isEmpty) return;
    if (backgroundColor != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor!);
    }
    final count = ((size.width * size.height / 10000) * density).round().clamp(
      0,
      particles.length,
    );
    final t = time.value * speed;
    final shift = touch.value;
    final dot = Paint();
    for (var i = 0; i < count; i++) {
      final p = particles[i];
      final amp = driftAmplitude * p.z;
      final position = Offset(
        p.fx * size.width +
            math.sin(t * p.freqX + p.phaseX) * amp +
            shift.dx * p.z,
        p.fy * size.height +
            math.cos(t * p.freqY + p.phaseY) * amp +
            shift.dy * p.z,
      );
      final radius = baseSize * p.z * math.max(.25, 1 + .8 * p.sizeJitter);
      final alpha = .45 + .45 * (.5 + .5 * math.sin(t * .8 + p.twinklePhase));
      dot.color = colors[p.colorIndex % colors.length].withValues(
        alpha: alpha * (.5 + .5 * p.z),
      );
      canvas.drawCircle(position, radius, dot);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.particles != particles ||
      oldDelegate.density != density ||
      oldDelegate.colors != colors ||
      oldDelegate.baseSize != baseSize ||
      oldDelegate.driftAmplitude != driftAmplitude ||
      oldDelegate.speed != speed ||
      oldDelegate.backgroundColor != backgroundColor;
}
