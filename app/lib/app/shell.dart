import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/live_updates.dart';
import '../core/theme/theme.dart';
import '../core/widgets/widgets.dart';

const _barHeight = 68.0;
const _orbSize = 64.0;
const _orbLift = 12.0;

/// Space tab pages must leave at the bottom so content clears the bottom bar and the raised AI button.
double dockClearance(BuildContext context) =>
    _barHeight + 28 + MediaQuery.paddingOf(context).bottom;

class _Tab {
  const _Tab(this.label, this.icon, this.selected, this.path);
  final String label;
  final IconData icon, selected;
  final String path;
}

// Outline icons in both states: selection is shown by the blue pill and label, not by swapping glyphs.
const _tabs = [
  _Tab('Discover', Icons.explore_outlined, Icons.explore_outlined, '/'),
  _Tab('Stays', Icons.bed_outlined, Icons.bed_outlined, '/stays'),
  _Tab('Trips', Icons.route_outlined, Icons.route_outlined, '/trips'),
  _Tab(
    'Me',
    Icons.person_outline_rounded,
    Icons.person_outline_rounded,
    '/account',
  ),
];

int _indexFor(String loc) {
  if (loc.startsWith('/stays')) return 1;
  if (loc.startsWith('/trips')) return 2;
  if (loc.startsWith('/account')) return 3;
  return 0;
}

/// Tab scaffold: content runs behind a white bottom bar docked to the screen edge with the AI button raised at its centre.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(liveUpdatesProvider);
    ref.listen(liveEventProvider, (_, event) {
      final data = event?['data'];
      if (data is! Map) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              '${data['title'] ?? 'Update'}: ${data['body'] ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
    });
    final idx = _indexFor(location);
    return Scaffold(
      extendBody: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: child,
      ),
      bottomNavigationBar: _Dock(index: idx),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    // The orb sits inside this widget's own bounds (not overflowing them) so its whole area receives taps.
    return SizedBox(
      height: _barHeight + _orbLift + bottom,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _barHeight + bottom,
              padding: EdgeInsets.only(bottom: bottom),
              decoration: BoxDecoration(
                color: Tokens.surface,
                border: const Border(top: BorderSide(color: Tokens.border)),
                boxShadow: [
                  BoxShadow(
                    color: Tokens.charcoal.withValues(alpha: .06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _item(context, 0)),
                  Expanded(child: _item(context, 1)),
                  const SizedBox(width: _orbSize + 8),
                  Expanded(child: _item(context, 2)),
                  Expanded(child: _item(context, 3)),
                ],
              ),
            ),
          ),
          const Positioned(top: 0, child: _Orb()),
        ],
      ),
    );
  }

  String _label(BuildContext context, int i) {
    final l = context.l10n;
    return [l.tabDiscover, l.tabStays, l.tabTrips, l.tabMe][i];
  }

  Widget _item(BuildContext context, int i) {
    final t = _tabs[i];
    final active = i == index;
    final reduce = MediaQuery.of(context).disableAnimations;
    final d = reduce ? Duration.zero : const Duration(milliseconds: 260);
    return Semantics(
      selected: active,
      child: Pressable(
        onTap: () {
          if (!active) context.go(t.path);
        },
        scale: 0.92,
        semanticLabel: _label(context, i),
        radius: 20,
        child: SizedBox(
          height: _barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: d,
                curve: Curves.easeOutCubic,
                width: active ? 52 : 44,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? Tokens.tint : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedScale(
                  scale: active ? 1.06 : 1,
                  duration: d,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    active ? t.selected : t.icon,
                    size: 24,
                    color: active ? Tokens.primary : Tokens.inkMuted,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: d,
                style: Type.body(
                  11,
                  weight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? Tokens.primaryText : Tokens.inkMuted,
                  height: 1.1,
                ),
                child: Text(
                  _label(context, i),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The centre button: opens the AI travel guide. Sunset orange with a navy sparkle and a white ring; it glows gently
/// unless the system asks for reduced motion.
class _Orb extends StatefulWidget {
  const _Orb();
  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () {
      tick(true);
      context.push('/assistant');
    },
    scale: 0.92,
    haptic: false,
    radius: 99,
    semanticLabel: context.l10n.askAiGuide,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final v = Curves.easeInOut.transform(_c.value);
        return Container(
          width: _orbSize,
          height: _orbSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: Tokens.sunrise,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Tokens.accent.withValues(alpha: .40 + .15 * v),
                blurRadius: 16 + 8 * v,
                spreadRadius: 0.5 * v,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Tokens.charcoal.withValues(alpha: .10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Tokens.onAccent,
        size: 28,
      ),
    ),
  );
}
