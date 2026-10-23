import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/live_updates.dart';
import '../core/theme/theme.dart';
import '../core/widgets/widgets.dart';

/// Space tab pages must leave at the bottom so content clears the floating dock.
double dockClearance(BuildContext context) => 104 + MediaQuery.paddingOf(context).bottom;

class _Tab {
  const _Tab(this.label, this.icon, this.selected, this.path);
  final String label;
  final IconData icon, selected;
  final String path;
}

const _tabs = [
  _Tab('Discover', Icons.explore_outlined, Icons.explore_rounded, '/'),
  _Tab('Stays', Icons.bed_outlined, Icons.bed_rounded, '/stays'),
  _Tab('Trips', Icons.route_outlined, Icons.route_rounded, '/trips'),
  _Tab('Me', Icons.person_outline_rounded, Icons.person_rounded, '/account'),
];

int _indexFor(String loc) {
  if (loc.startsWith('/stays')) return 1;
  if (loc.startsWith('/trips')) return 2;
  if (loc.startsWith('/account')) return 3;
  return 0;
}

/// Tab scaffold: content runs behind a floating glass dock with the AI orb at its centre.
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
        ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text('${data['title'] ?? 'Update'}: ${data['body'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis)));
    });
    final idx = _indexFor(location);
    return Scaffold(
      extendBody: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent), child: child),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + (bottom > 0 ? bottom * 0.6 : 8)),
      child: SizedBox(
        height: 74,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Tokens.forestDeep.withValues(alpha: .22), blurRadius: 30, offset: const Offset(0, 14))],
              ),
              child: Glass(
                radius: 30,
                blur: 24,
                tint: const Color(0xE6FFFFFF),
                border: Colors.white,
                child: Row(children: [
                  Expanded(child: _item(context, 0)),
                  Expanded(child: _item(context, 1)),
                  const SizedBox(width: 74),
                  Expanded(child: _item(context, 2)),
                  Expanded(child: _item(context, 3)),
                ]),
              ),
            ),
          ),
          Positioned(top: -14, child: const _Orb()),
        ]),
      ),
    );
  }

  Widget _item(BuildContext context, int i) {
    final t = _tabs[i];
    final active = i == index;
    return Pressable(
      onTap: () {
        if (!active) context.go(t.path);
      },
      scale: 0.9,
      semanticLabel: t.label,
      child: SizedBox(
        height: 74,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: active ? Tokens.forest.withValues(alpha: .12) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(active ? t.selected : t.icon, key: ValueKey(active), size: 24, color: active ? Tokens.forest : Tokens.inkMuted),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: Type.body(11, weight: active ? FontWeight.w800 : FontWeight.w600, color: active ? Tokens.forest : Tokens.inkMuted),
            child: Text(t.label),
          ),
        ]),
      ),
    );
  }
}

/// The centre button: opens the AI travel guide. It breathes gently so it reads as alive.
class _Orb extends StatefulWidget {
  const _Orb();
  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);

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
        semanticLabel: 'Ask the AI travel guide',
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final v = Curves.easeInOut.transform(_c.value);
            return Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFF0B85A), Tokens.terracotta], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: Tokens.ivory, width: 4),
                boxShadow: [
                  BoxShadow(color: Tokens.terracotta.withValues(alpha: .35 + .2 * v), blurRadius: 18 + 10 * v, spreadRadius: 1 + 2 * v, offset: const Offset(0, 8)),
                ],
              ),
              child: child,
            );
          },
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 29),
        ),
      );
}
