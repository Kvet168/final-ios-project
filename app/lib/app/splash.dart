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
      ..color = Tokens.ivory.withValues(alpha: 0.92);
    final ringT = Curves.easeInOutCubic.transform(_seg(0, 0.45));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.92), -math.pi / 2, math.pi * 2 * ringT, false, ring);

    final tickT = _seg(0.25, 0.6);
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.016
      ..color = Tokens.ivory.withValues(alpha: 0.55 * tickT);
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      final inner = r * (i % 6 == 0 ? 0.78 : 0.84);
      canvas.drawLine(c + Offset(math.sin(a), -math.cos(a)) * inner, c + Offset(math.sin(a), -math.cos(a)) * r * 0.88, tick);
    }

    final starT = Curves.easeOutBack.transform(_seg(0.4, 0.75));
    final star = Paint()..color = Tokens.ivory;
    final long = r * 0.78 * starT, short = r * 0.17 * starT;
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 2;
      final dir = Offset(math.sin(a), -math.cos(a));
      final side = Offset(math.cos(a), math.sin(a));
      canvas.drawPath(Path()..moveTo(c.dx + dir.dx * long, c.dy + dir.dy * long)..lineTo(c.dx + side.dx * short, c.dy + side.dy * short)..lineTo(c.dx, c.dy)..lineTo(c.dx - side.dx * short, c.dy - side.dy * short)..close(), star);
    }

    final needleT = Curves.elasticOut.transform(_seg(0.6, 1));
    final angle = math.pi / 4 + (1 - needleT) * math.pi * 1.1;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final nl = r * 0.55, nw = r * 0.11;
    canvas.drawPath(Path()..moveTo(0, -nl)..lineTo(nw, 0)..lineTo(-nw, 0)..close(), Paint()..color = Tokens.gold);
    canvas.drawPath(Path()..moveTo(0, nl)..lineTo(nw, 0)..lineTo(-nw, 0)..close(), Paint()..color = Tokens.terracotta);
    canvas.restore();
    canvas.drawCircle(c, r * 0.05, Paint()..color = Tokens.forestDeep);
    canvas.drawCircle(c, r * 0.022, Paint()..color = Tokens.gold);
  }

  @override
  bool shouldRepaint(covariant CompassPainter old) => old.t != t;
}

/// Branded launch animation that doubles as a warm-up: while the compass draws itself the app wakes the API
/// and loads the home feed, so the first screen is ready the moment the splash lifts.
class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _run();
  }

  Future<void> _run() async {
    final started = DateTime.now();
    await Future.any([ref.read(apiProvider).warmUp(), Future<void>.delayed(const Duration(milliseconds: 4200))]);
    final elapsed = DateTime.now().difference(started);
    const minimum = Duration(milliseconds: 1900);
    if (elapsed < minimum) await Future<void>.delayed(minimum - elapsed);
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(textDirection: TextDirection.ltr, children: [
      widget.child,
      IgnorePointer(
        ignoring: _done,
        child: AnimatedOpacity(
          opacity: _done ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: Container(
            decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(-0.3, -0.5), radius: 1.3, colors: [Color(0xFF2B6152), Tokens.forestDeep])),
            child: Center(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 132, height: 132, child: CustomPaint(painter: CompassPainter(_c.value))),
                  const SizedBox(height: 34),
                  Opacity(
                    opacity: Curves.easeOut.transform(((_c.value - 0.45) / 0.4).clamp(0.0, 1.0)),
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - ((_c.value - 0.45) / 0.4).clamp(0.0, 1.0))),
                      child: Column(children: [
                        Text('WAYFARER', style: Type.display(30, color: Tokens.ivory, weight: FontWeight.w600, spacing: 8)),
                        const SizedBox(height: 10),
                        Text('Travel, planned beautifully', style: Type.body(13.5, color: Tokens.ivory.withValues(alpha: .7), weight: FontWeight.w500, spacing: 0.6)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
