import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/theme/theme.dart';
import '../l10n/app_localizations.dart';

/// Draws the WAYFARER compass. [t] in 0..1 drives the reveal: ring, ticks, star, then the needle swinging into place.
class CompassPainter extends CustomPainter {
  CompassPainter(this.t, {this.sway = 0});
  final double t;

  /// Small continuous swing of the needle once it has settled (radians).
  final double sway;

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
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.92),
      -math.pi / 2,
      math.pi * 2 * ringT,
      false,
      ring,
    );

    final tickT = _seg(0.25, 0.6);
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.016
      ..color = Tokens.pageBg.withValues(alpha: 0.55 * tickT);
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      final inner = r * (i % 6 == 0 ? 0.78 : 0.84);
      canvas.drawLine(
        c + Offset(math.sin(a), -math.cos(a)) * inner,
        c + Offset(math.sin(a), -math.cos(a)) * r * 0.88,
        tick,
      );
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
    final angle = math.pi / 4 + (1 - needleT) * math.pi * 1.1 + sway * needleT;
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
      Paint()..color = Tokens.deepRed,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, nl)
        ..lineTo(nw, 0)
        ..lineTo(-nw, 0)
        ..close(),
      Paint()..color = const Color(0xFFF4A3AE),
    );
    canvas.restore();
    canvas.drawCircle(c, r * 0.05, Paint()..color = Colors.white);
    canvas.drawCircle(c, r * 0.022, Paint()..color = Tokens.deepRed);
  }

  @override
  bool shouldRepaint(covariant CompassPainter old) =>
      old.t != t || old.sway != sway;
}

/// Launch screen that doubles as a warm-up: while it shows, the app wakes the API and loads the home feed, so the first
/// screen is ready the moment it lifts. Light and quiet so it continues straight on from the white native launch screen.
class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
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
      _c.value = 1;
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
    await Future.any([
      ref.read(apiProvider).warmUp(),
      Future<void>.delayed(const Duration(milliseconds: 4200)),
    ]);
    final elapsed = DateTime.now().difference(started);
    const minimum = Duration(milliseconds: 1600);
    if (elapsed < minimum) await Future<void>.delayed(minimum - elapsed);
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _c.dispose();
    _loop.dispose();
    super.dispose();
  }

  double _step(double a, double b) =>
      Curves.easeOutCubic.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        // Positioned.fill: without it the overlay is only as big as its content and hugs the left edge.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _done,
            child: AnimatedOpacity(
              opacity: _done ? 0 : 1,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              // The overlay sits above the Navigator, so it needs its own Material for text to render without debug underlines.
              child: Material(
                color: Colors.white,
                child: Semantics(
                  liveRegion: true,
                  label: l.splashLoading,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_c, _loop]),
                    builder: (_, _) {
                      final mark = _step(0, 0.45);
                      final text = _step(0.3, 0.8);
                      return Container(
                        color: Colors.white,
                        child: SafeArea(
                          child: Column(
                            children: [
                              const Spacer(flex: 5),
                              Opacity(
                                opacity: mark,
                                child: Transform.scale(
                                  scale: 0.9 + 0.1 * mark,
                                  child: Image.asset('assets/logo.png', width: 240, fit: BoxFit.contain),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Opacity(
                                opacity: text,
                                child: Transform.translate(
                                  offset: Offset(0, 8 * (1 - text)),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        l.tagline,
                                        textAlign: TextAlign.center,
                                        style: Type.body(
                                          14,
                                          color: Tokens.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(flex: 6),
                              Opacity(
                                opacity: text,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: SizedBox(
                                        width: 120,
                                        height: 3,
                                        child: Stack(
                                          children: [
                                            Container(color: Tokens.tint),
                                            FractionallySizedBox(
                                              widthFactor: 0.35,
                                              alignment: Alignment(
                                                _loop.value * 2.7 - 1.35,
                                                0,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Tokens.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      height: 40,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Padding(
                                          key: ValueKey(_slow),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                          ),
                                          child: Text(
                                            _slow
                                                ? l.splashSlow
                                                : l.splashReady,
                                            textAlign: TextAlign.center,
                                            style: Type.body(
                                              12.5,
                                              color: Tokens.inkMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
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
