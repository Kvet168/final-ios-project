import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/theme/theme.dart';

/// Draws the WAYFARER compass. [t] in 0..1 drives the reveal: ring, ticks, star, then the needle swinging into place.
class CompassPainter extends CustomPainter {
  CompassPainter(this.t);
  final double t;

  double _seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.045
      ..strokeCap = StrokeCap.round
      ..color = Tokens.pageBg.withValues(alpha: 0.92);
    final ringT = Curves.easeInOutCubic.transform(_seg(0, 0.45));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.92), -math.pi / 2, math.pi * 2 * ringT, false, ring);

    final tickT = _seg(0.25, 0.6);
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.016
      ..color = Tokens.pageBg.withValues(alpha: 0.55 * tickT);
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      final inner = r * (i % 6 == 0 ? 0.78 : 0.84);
      canvas.drawLine(c + Offset(math.sin(a), -math.cos(a)) * inner, c + Offset(math.sin(a), -math.cos(a)) * r * 0.88, tick);
    }

    final starT = Curves.easeOutBack.transform(_seg(0.4, 0.75));
    final star = Paint()..color = Tokens.pageBg;
    final long = r * 0.78 * starT, short = r * 0.17 * starT;
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 2;
      final dir = Offset(math.sin(a), -math.cos(a));
      final side = Offset(math.cos(a), math.sin(a));
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + dir.dx * long, c.dy + dir.dy * long)
          ..lineTo(c.dx + side.dx * short, c.dy + side.dy * short)
          ..lineTo(c.dx, c.dy)
          ..lineTo(c.dx - side.dx * short, c.dy - side.dy * short)
          ..close(),
        star,
      );
    }

    final needleT = Curves.elasticOut.transform(_seg(0.6, 1));
    final angle = math.pi / 4 + (1 - needleT) * math.pi * 1.1;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final nl = r * 0.55, nw = r * 0.11;
    canvas.drawPath(
      Path()
        ..moveTo(0, -nl)
        ..lineTo(nw, 0)
        ..lineTo(-nw, 0)
        ..close(),
      Paint()..color = Tokens.cta,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, nl)
        ..lineTo(nw, 0)
        ..lineTo(-nw, 0)
        ..close(),
      Paint()..color = Tokens.deepRed,
    );
    canvas.restore();
    canvas.drawCircle(c, r * 0.05, Paint()..color = Colors.white);
    canvas.drawCircle(c, r * 0.022, Paint()..color = Tokens.deepRed);
  }

  @override
  bool shouldRepaint(covariant CompassPainter old) => old.t != t;
}

/// Sunset glow on the horizon with three drifting wave layers. [phase] is 0..1 and loops seamlessly because every layer
/// completes a whole number of cycles per loop; [reveal] fades the scene in.
class _OceanPainter extends CustomPainter {
  _OceanPainter(this.phase, this.reveal);
  final double phase, reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.74;
    canvas.drawCircle(
      Offset(w / 2, horizon),
      w * 0.62,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Tokens.onDarkAccent.withValues(alpha: 0.38 * reveal),
            Tokens.onDarkAccent.withValues(alpha: 0.12 * reveal),
            Tokens.onDarkAccent.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: Offset(w / 2, horizon), radius: w * 0.62)),
    );
    const layers = [
      (offset: 4.0, amp: 7.0, length: 0.95, alpha: 0.07, navy: false),
      (offset: 30.0, amp: 10.0, length: 0.75, alpha: 0.11, navy: false),
      (offset: 58.0, amp: 12.0, length: 0.6, alpha: 0.55, navy: true),
    ];
    for (var i = 0; i < layers.length; i++) {
      final l = layers[i];
      final dir = i.isEven ? 1.0 : -1.0;
      final path = Path()..moveTo(0, h);
      for (double x = 0; x <= w + 6; x += 6) {
        final y = horizon + l.offset + math.sin((x / (w * l.length) + dir * phase * (i + 1)) * math.pi * 2) * l.amp;
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.close();
      canvas.drawPath(path, Paint()..color = (l.navy ? Tokens.deepRed : Colors.white).withValues(alpha: l.alpha * reveal));
    }
  }

  @override
  bool shouldRepaint(covariant _OceanPainter old) => old.phase != phase || old.reveal != reveal;
}

/// Branded launch animation that doubles as a warm-up: while the compass draws itself the app wakes the API
/// and loads the home feed, so the first screen is ready the moment the splash lifts.
class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 9));
  bool _done = false;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _run();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  Future<void> _run() async {
    final started = DateTime.now();
    Future<void>.delayed(const Duration(milliseconds: 2300), () {
      if (mounted && !_done) setState(() => _slow = true);
    });
    await Future.any([ref.read(apiProvider).warmUp(), Future<void>.delayed(const Duration(milliseconds: 4200))]);
    final elapsed = DateTime.now().difference(started);
    const minimum = Duration(milliseconds: 1900);
    if (elapsed < minimum) await Future<void>.delayed(minimum - elapsed);
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _c.dispose();
    _loop.dispose();
    super.dispose();
  }

  double _step(double a, double b) => ((_c.value - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: _done,
          child: AnimatedOpacity(
            opacity: _done ? 0 : 1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD63A50), Color(0xFFB02E44), Tokens.deepRed],
                  stops: [0, 0.55, 1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              // The overlay sits above the Navigator, so it needs its own Material for text to render without debug underlines.
              child: Material(
                type: MaterialType.transparency,
                child: Semantics(
                  liveRegion: true,
                  label: 'Loading WAYFARER',
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_c, _loop]),
                    builder: (_, _) {
                      final text = Curves.easeOut.transform(_step(0.45, 0.85));
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(painter: _OceanPainter(_loop.value, Curves.easeOut.transform(_step(0.1, 0.8)))),
                          SafeArea(
                            child: Column(
                              children: [
                                const Spacer(flex: 5),
                                Container(
                                  width: 156,
                                  height: 156,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.16 * _step(0.4, 1)), blurRadius: 70, spreadRadius: 6)],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: CustomPaint(painter: CompassPainter(_c.value)),
                                ),
                                const SizedBox(height: 30),
                                Opacity(
                                  opacity: text,
                                  child: Transform.translate(
                                    offset: Offset(0, 10 * (1 - text)),
                                    child: Column(
                                      children: [
                                        Text(
                                          'WAYFARER',
                                          style: Type.display(32, color: Colors.white, weight: FontWeight.w600, spacing: 9),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Travel, planned beautifully',
                                          style: Type.body(14, color: Colors.white.withValues(alpha: 0.92), weight: FontWeight.w500, spacing: 0.6),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 34),
                                Opacity(
                                  opacity: text,
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: SizedBox(
                                          width: 168,
                                          height: 3,
                                          child: Stack(
                                            children: [
                                              Container(color: Colors.white.withValues(alpha: 0.18)),
                                              FractionallySizedBox(
                                                widthFactor: 0.38,
                                                alignment: Alignment((((_loop.value * 4) % 1.0) * 2.6) - 1.3, 0),
                                                child: Container(
                                                  decoration: BoxDecoration(color: Tokens.cta, borderRadius: BorderRadius.circular(3)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 350),
                                        child: Text(
                                          _slow ? 'Waking the server, this can take a moment' : 'Getting things ready',
                                          key: ValueKey(_slow),
                                          textAlign: TextAlign.center,
                                          style: Type.body(12.5, color: Colors.white.withValues(alpha: 0.92), weight: FontWeight.w500, spacing: 0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(flex: 6),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
