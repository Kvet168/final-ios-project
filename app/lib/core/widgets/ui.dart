import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// Light haptic tick, ignored on platforms without a vibrator.
void tick([bool strong = false]) {
  if (kIsWeb) return;
  strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
}

/// Scales down slightly while pressed and ticks on tap: gives every card a tactile feel.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.haptic = true, this.radius = Tokens.radius, this.semanticLabel});
  final Widget child;
  final VoidCallback? onTap;
  final double scale, radius;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) tick();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down && !reduce ? widget.scale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fades and slides content in once, optionally staggered. Used to make lists feel composed rather than dumped.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero, this.dy = 18, this.duration = const Duration(milliseconds: 520)});
  final Widget child;
  final Duration delay, duration;
  final double dy;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(opacity: _a.value, child: Transform.translate(offset: Offset(0, (1 - _a.value) * widget.dy), child: child)),
      child: widget.child,
    );
  }
}

/// Frosted-glass surface for controls floating over photography.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.radius = 22, this.blur = 18, this.tint = const Color(0x33FFFFFF), this.border = const Color(0x40FFFFFF), this.padding});
  final Widget child;
  final double radius, blur;
  final Color tint, border;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(radius), border: Border.all(color: border)),
            child: child,
          ),
        ),
      );
}

/// Circular glass button used for back / share / save over hero images.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap, this.tooltip, this.color = Colors.white, this.size = 44});
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip ?? '',
        child: Pressable(
          onTap: onTap,
          radius: size,
          child: Glass(
            radius: size,
            tint: const Color(0x400F172A),
            child: SizedBox(width: size, height: size, child: Icon(icon, color: color, size: 22)),
          ),
        ),
      );
}

/// Animated shimmer used by skeleton placeholders.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;
  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (r) => LinearGradient(
            begin: Alignment(-1.4 + 2.8 * _c.value, -0.3),
            end: Alignment(-0.4 + 2.8 * _c.value, 0.3),
            colors: const [Tokens.neutralTint, Colors.white, Tokens.neutralTint],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(r),
          child: child,
        ),
      );
}

/// Selectable pill used for filters and categories.
class WChip extends StatelessWidget {
  const WChip(this.label, {super.key, this.selected = false, this.onTap, this.icon, this.count});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : Tokens.ink;
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      radius: 999,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Tokens.primaryText : Tokens.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? Tokens.primaryText : Tokens.border),
          boxShadow: selected ? [BoxShadow(color: Tokens.primaryText.withValues(alpha: .28), blurRadius: 14, offset: const Offset(0, 6))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 17, color: selected ? Colors.white : Tokens.primary), const SizedBox(width: 7)],
          Text(label, style: Type.body(13.5, weight: FontWeight.w700, color: fg)),
          if (count != null) ...[const SizedBox(width: 6), Text('$count', style: Type.body(12, weight: FontWeight.w600, color: selected ? Tokens.onDarkMuted : Tokens.inkMuted))],
        ]),
      ),
    );
  }
}

/// Editorial section title: small caps eyebrow, serif title, optional action.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.eyebrow, this.action, this.onAction, this.padding = const EdgeInsets.fromLTRB(20, 34, 20, 14)});
  final String title;
  final String? eyebrow, action;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (eyebrow != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(eyebrow!.toUpperCase(), style: Type.label(11, color: Tokens.primaryText))),
              Semantics(header: true, child: Text(title, style: Type.display(25))),
            ]),
          ),
          if (action != null)
            Pressable(
              onTap: onAction,
              radius: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(action!, style: Type.body(13.5, weight: FontWeight.w700, color: Tokens.primaryText)),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Tokens.primary),
                ]),
              ),
            ),
        ]),
      );
}

/// Animated wishlist heart with a small pop.
class HeartButton extends StatelessWidget {
  const HeartButton({super.key, required this.active, required this.onTap, this.size = 44});
  final bool active;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () {
          tick(true);
          onTap();
        },
        radius: size,
        semanticLabel: active ? 'Remove from wishlist' : 'Save to wishlist',
        child: Glass(
          radius: size,
          tint: const Color(0x400F172A),
          child: SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(active),
              tween: Tween(begin: active ? 0.6 : 1.0, end: 1.0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.elasticOut,
              builder: (_, v, _) => Transform.scale(scale: v, child: Icon(active ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: active ? Tokens.heart : Colors.white, size: 22)),
            ),
          ),
        ),
      );
}

/// Numbers ease up to their value; used for prices and stats.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.builder, this.duration = const Duration(milliseconds: 700)});
  final double value;
  final Widget Function(double v) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => builder(v),
      );
}

/// Pulsing dots shown while the assistant is composing an answer.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});
  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Builder(builder: (_) {
              final w = 0.5 + 0.5 * math.sin((_c.value * 2 - i * 0.18) * math.pi * 2);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 7,
                height: 7 + 5 * w,
                decoration: BoxDecoration(color: Tokens.primary.withValues(alpha: 0.3 + 0.55 * w), borderRadius: BorderRadius.circular(6)),
              );
            }),
        ]),
      );
}

/// Perforated ticket silhouette used by the booking confirmation.
class TicketShape extends CustomClipper<Path> {
  const TicketShape({this.notchY = 0.62, this.notchRadius = 14, this.radius = 26});
  final double notchY, notchRadius, radius;

  @override
  Path getClip(Size s) {
    final y = s.height * notchY;
    final p = Path()
      ..moveTo(radius, 0)
      ..lineTo(s.width - radius, 0)
      ..arcToPoint(Offset(s.width, radius), radius: Radius.circular(radius))
      ..lineTo(s.width, y - notchRadius)
      ..arcToPoint(Offset(s.width, y + notchRadius), radius: Radius.circular(notchRadius), clockwise: false)
      ..lineTo(s.width, s.height - radius)
      ..arcToPoint(Offset(s.width - radius, s.height), radius: Radius.circular(radius))
      ..lineTo(radius, s.height)
      ..arcToPoint(Offset(0, s.height - radius), radius: Radius.circular(radius))
      ..lineTo(0, y + notchRadius)
      ..arcToPoint(Offset(0, y - notchRadius), radius: Radius.circular(notchRadius), clockwise: false)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant TicketShape old) => old.notchY != notchY;
}

/// Dashed horizontal rule for ticket perforations and timelines.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.color = Tokens.border, this.dash = 6, this.gap = 5, this.thickness = 1.6});
  final Color color;
  final double dash, gap, thickness;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final n = (c.maxWidth / (dash + gap)).floor();
        return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < n; i++) Container(width: dash, height: thickness, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        ]);
      });
}

/// Static status-bar tone for screens whose top edge is a dark photo or gradient (light icons).
class StatusTone extends StatelessWidget {
  const StatusTone.light({super.key, required this.child}) : light = true;
  final Widget child;
  final bool light;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: (light ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
        child: child,
      );
}

/// Status-bar icons are light while a dark header is at the top of the scroll view and turn dark once it has scrolled away.
class ToneOnScroll extends StatefulWidget {
  const ToneOnScroll({super.key, required this.child, this.threshold = 110});
  final Widget child;
  final double threshold;

  @override
  State<ToneOnScroll> createState() => _ToneOnScrollState();
}

class _ToneOnScrollState extends State<ToneOnScroll> {
  bool _light = true;

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0) {
            final light = n.metrics.pixels < widget.threshold;
            if (light != _light) setState(() => _light = light);
          }
          return false;
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: (_light ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
          child: widget.child,
        ),
      );
}
