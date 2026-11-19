import 'package:flutter/material.dart';

/// The Google "G" mark, drawn from the official 48x48 outline so it needs no network or asset.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleLogoPainter()),
    ),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  // Official colours and outlines (viewBox 0 0 48 48). The one arc in the yellow piece is a cubic here.
  static const _parts = <(Color, String)>[
    (
      Color(0xFF4285F4),
      'M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 5.08-4.39 6.64v5.52h7.11c4.16-3.83 6.56-9.47 6.56-16.17z',
    ),
    (
      Color(0xFF34A853),
      'M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 2.1-7.45 2.1-5.73 0-10.58-3.87-12.31-9.07H4.34v5.7C7.96 41.07 15.4 46 24 46z',
    ),
    (
      Color(0xFFFBBC05),
      'M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34C2.85 17.09 2 20.45 2 24c0 3.55.85 6.91 2.34 9.88l7.35-5.7z',
    ),
    (
      Color(0xFFEA4335),
      'M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 24 2 15.4 2 7.96 6.93 4.34 14.12l7.35 5.7c1.73-5.2 6.58-9.07 12.31-9.07z',
    ),
  ];

  static final _num = RegExp(r'-?(?:\d+\.?\d*|\.\d+)');

  Path _parse(String d) {
    final p = Path();
    final tokens = RegExp(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)').allMatches(d);
    final items = [for (final m in tokens) m.group(0)!];
    var i = 0, x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
    String cmd = 'M';
    double n() => double.parse(_num.firstMatch(items[i++])!.group(0)!);
    while (i < items.length) {
      if (RegExp(r'[A-Za-z]').hasMatch(items[i])) cmd = items[i++];
      final rel = cmd == cmd.toLowerCase();
      switch (cmd.toLowerCase()) {
        case 'm':
          x = n() + (rel ? x : 0);
          y = n() + (rel ? y : 0);
          sx = x;
          sy = y;
          p.moveTo(x, y);
          cmd = rel ? 'l' : 'L';
        case 'l':
          x = n() + (rel ? x : 0);
          y = n() + (rel ? y : 0);
          p.lineTo(x, y);
        case 'h':
          x = n() + (rel ? x : 0);
          p.lineTo(x, y);
        case 'v':
          y = n() + (rel ? y : 0);
          p.lineTo(x, y);
        case 'c':
          final a = n() + (rel ? x : 0), b = n() + (rel ? y : 0);
          final c = n() + (rel ? x : 0), e = n() + (rel ? y : 0);
          final nx = n() + (rel ? x : 0), ny = n() + (rel ? y : 0);
          p.cubicTo(a, b, c, e, nx, ny);
          x = nx;
          y = ny;
        case 's':
          // Smooth curves are not used by these outlines; treat as a plain curve to the end point.
          n();
          n();
          final nx = n() + (rel ? x : 0), ny = n() + (rel ? y : 0);
          p.lineTo(nx, ny);
          x = nx;
          y = ny;
        case 'z':
          p.close();
          x = sx;
          y = sy;
      }
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    for (final (color, d) in _parts) {
      canvas.drawPath(_parse(d), Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
